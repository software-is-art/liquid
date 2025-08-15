defmodule Runtime.BEAM do
  @moduledoc """
  Runtime adapter that wraps an in-VM Elixir behavior function.

  The function must have arity 3: `fn id, state, msg -> {:continue, new_state} | {:become, new_fun, new_state}`.
  """
  use BehaviorRuntime

  @impl true
  def init(opts) do
    case Keyword.fetch(opts, :behavior) do
      {:ok, fun} when is_function(fun, 3) ->
        metadata = Keyword.get(opts, :metadata, %{})
        {:ok, fun, metadata}
      _ ->
        {:error, :invalid_behavior}
    end
  end

  @impl true
  def handle(fun, id, state, msg) when is_function(fun, 3) do
    case fun.(id, state, msg) do
      {:continue, new_state} -> {:continue, new_state, fun}
      {:become, new_fun, new_state} when is_function(new_fun, 3) ->
        {:become, new_fun, new_state}
    end
  end

  @impl true
  def describe(_fun), do: %{}

  @impl true
  def terminate(_fun), do: :ok
end

