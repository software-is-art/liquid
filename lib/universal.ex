defmodule Universal do
  @moduledoc """
  A server that becomes anything through conversation.
  Not evolution. Transformation.
  """
  
  def spawn_universal(id \\ nil) do
    id = id || generate_id()
    pid = spawn(fn -> universal_loop(id, %{}, &default_behavior/3, %{}) end)
    Process.register(pid, id)
    # Log spawn event
    safe_registry(fn ->
      LiquidRegistry.log(id, :spawned, %{})
    end)
    {:ok, pid, id}
  end
  
  defp universal_loop(id, state, behavior, metadata) do
    receive do
      {:become, new_behavior, new_metadata} when is_function(new_behavior, 3) and is_map(new_metadata) ->
        # Transform and update metadata
        safe_registry(fn ->
          LiquidRegistry.announce(id, new_metadata)
          LiquidRegistry.log(id, :transformed, %{via: :become})
        end)
        universal_loop(id, state, new_behavior, new_metadata)

      {:become, new_behavior} when is_function(new_behavior, 3) ->
        # Instant transformation
        # Announce and log if we have metadata capabilities
        safe_registry(fn ->
          LiquidRegistry.announce(id, metadata)
          LiquidRegistry.log(id, :transformed, %{via: :become})
        end)
        universal_loop(id, state, new_behavior, metadata)
      
      {:transform_via_ai, description, from} ->
        # Natural language transformation
        context = Context.build_minimal_context(description)
        case AI.transform(description, context, id) do
          {:ok, new_behavior, new_metadata} ->
            send(from, {:transformed, id})
            safe_registry(fn ->
              LiquidRegistry.announce(id, new_metadata)
              LiquidRegistry.log(id, :transformed, %{via: :ai, description: description})
            end)
            universal_loop(id, state, new_behavior, new_metadata)
          error ->
            send(from, {:transform_failed, id, error})
            universal_loop(id, state, behavior, metadata)
        end
      
      {:describe_self, caller, ref} ->
        # Every server can explain what it is
        send(caller, {ref, metadata})
        universal_loop(id, state, behavior, metadata)
      
      {:get_state, caller, ref} ->
        # Allow inspection of current state
        send(caller, {ref, state})
        universal_loop(id, state, behavior, metadata)

      {:capability, op, args, from} ->
        # Mediated capability execution based on metadata.capabilities
        caps = Map.get(metadata, :capabilities, [])
        if op in caps do
          LiquidRegistry.log(id, :capability_used, %{op: op, args: summarize_args(args)})
          result = Capabilities.execute(op, args, id)
          send(from, {:capability_result, id, op, result})
        else
          LiquidRegistry.log(id, :capability_denied, %{op: op})
          send(from, {:capability_error, id, op, :denied})
        end
        universal_loop(id, state, behavior, metadata)
      
      msg ->
        # Current behavior handles everything else
        case behavior.(id, state, msg) do
          {:continue, new_state} ->
            universal_loop(id, new_state, behavior, metadata)
          {:become, new_behavior, new_state} ->
            universal_loop(id, new_state, new_behavior, metadata)
        end
    end
  end
  
  defp default_behavior(_id, state, _msg) do
    # Does nothing until told to become something
    {:continue, state}
  end
  
  defp generate_id do
    # Simple ID generation
    :"universal_#{:erlang.unique_integer([:positive])}"
  end

  defp summarize_args(args) do
    case args do
      list when is_list(list) -> Enum.map(list, &summarize_arg/1)
      other -> summarize_arg(other)
    end
  end

  defp summarize_arg(arg) when is_binary(arg) do
    if byte_size(arg) > 64, do: String.slice(arg, 0, 64) <> "…", else: arg
  end
  defp summarize_arg(arg), do: arg

  defp safe_registry(fun) do
    try do
      fun.()
    rescue
      _ -> :ok
    end
  end
end
