defmodule Universal do
  @moduledoc """
  A server that becomes anything through conversation.
  Not evolution. Transformation.
  """
  
  def spawn_universal(id \\ nil) do
    id = id || generate_id()
    pid = spawn(fn -> universal_loop(id, %{}, &default_behavior/3, %{}) end)
    Process.register(pid, id)
    {:ok, pid, id}
  end
  
  defp universal_loop(id, state, behavior, metadata) do
    receive do
      {:become, new_behavior} when is_function(new_behavior, 3) ->
        # Instant transformation
        universal_loop(id, state, new_behavior, metadata)
      
      {:transform_via_ai, description, from} ->
        # Natural language transformation
        context = Context.build_minimal_context(description)
        case AI.transform(description, context, id) do
          {:ok, new_behavior, new_metadata} ->
            send(from, {:transformed, id})
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
end