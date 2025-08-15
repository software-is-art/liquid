defmodule Capabilities do
  @moduledoc """
  Mediated capability execution. Behaviors request capabilities via the
  Universal process instead of calling side-effectful functions directly.

  Supported ops: :spawn_child, :net_request, :log
  """

  @type op ::
          :spawn_child
          | :net_request
          | :log
          | :get_context
          | :get_registry
          | :get_history
          | :ai_transform
          | :apply_transform

  @doc """
  Request a capability from a Universal server by name or pid.
  Returns {:ok, result} | {:error, reason} synchronously with a timeout.
  """
  def request(pid_or_name, op, args, timeout \\ 2_000) do
    _ref = make_ref()
    send_to(pid_or_name, {:capability, op, args, self()})

    receive do
      {:capability_result, _id, ^op, result} -> {:ok, result}
      {:capability_error, _id, ^op, reason} -> {:error, reason}
    after
      timeout -> {:error, :timeout}
    end
  end

  @doc false
  def execute(:spawn_child, child_name, _caller_id) when is_atom(child_name) do
    Universal.spawn_universal(child_name)
  end
  def execute(:spawn_child, _args, _caller_id), do: {:error, :invalid_args}

  def execute(:net_request, %{method: method, url: url, body: body} = _req, _caller_id)
      when method in [:get, :post, :put, :patch, :delete] and is_binary(url) do
    try do
      case method do
        :get -> {:ok, Req.get!(url).body}
        :delete -> {:ok, Req.delete!(url).body}
        :post -> {:ok, Req.post!(url, json: body).body}
        :put -> {:ok, Req.put!(url, json: body).body}
        :patch -> {:ok, Req.patch!(url, json: body).body}
      end
    rescue
      e -> {:error, {:request_failed, e}}
    end
  end
  def execute(:net_request, _args, _caller_id), do: {:error, :invalid_args}

  def execute(:log, message, caller_id) do
    IO.puts("[#{caller_id}] #{to_string(message)}")
    :ok
  end

  def execute(:get_context, _args, _caller_id) do
    Liquid.context()
  end

  def execute(:get_registry, _args, _caller_id) do
    Liquid.registry()
  end

  def execute(:get_history, {:recent, n}, _caller_id) when is_integer(n) and n > 0 do
    LiquidRegistry.get_recent(n)
  end
  def execute(:get_history, {:by_id, id}, _caller_id) when is_atom(id) do
    LiquidRegistry.get_by(id)
  end
  def execute(:get_history, _args, _caller_id), do: {:error, :invalid_args}

  def execute(:ai_transform, description, caller_id) when is_binary(description) do
    context = Context.build_minimal_context(description)
    AI.transform(description, context, caller_id)
  end
  def execute(:ai_transform, _args, _caller_id), do: {:error, :invalid_args}

  def execute(:apply_transform, %{target: target, behavior: behavior, metadata: metadata}, _caller_id)
      when (is_pid(target) or is_atom(target)) and is_function(behavior, 3) and is_map(metadata) do
    send_to(target, {:become, behavior, metadata})
    :ok
  end
  def execute(:apply_transform, _args, _caller_id), do: {:error, :invalid_args}

  def execute(op, _args, _caller_id), do: {:error, {:unknown_capability, op}}

  defp send_to(pid, msg) when is_pid(pid), do: send(pid, msg)
  defp send_to(name, msg) when is_atom(name) do
    case Process.whereis(name) do
      nil -> :ok
      pid -> send(pid, msg)
    end
  end
end
