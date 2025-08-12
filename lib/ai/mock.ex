defmodule AI.Mock do
  @moduledoc """
  Mock AI backend for testing without external dependencies.
  Returns pre-defined behaviors based on description patterns.
  """
  
  def available?, do: true
  
  def transform(description, _context, _server_id) do
    description_lower = String.downcase(description)
    
    cond do
      String.contains?(description_lower, ["count", "counter"]) ->
        {:ok, Examples.counter_behavior(), 
         %{type: :counter, capabilities: [:increment, :decrement, :get], 
           description: description}}
      
      String.contains?(description_lower, ["echo", "repeat"]) ->
        {:ok, Examples.echo_behavior(),
         %{type: :echo, capabilities: [:echo],
           description: description}}
      
      String.contains?(description_lower, ["store", "accumulate", "collect"]) ->
        {:ok, Examples.accumulator_behavior(),
         %{type: :accumulator, capabilities: [:add, :get_all, :clear],
           description: description}}
      
      String.contains?(description_lower, ["work", "process", "task"]) ->
        {:ok, Examples.worker_behavior(),
         %{type: :worker, capabilities: [:work],
           description: description}}
      
      String.contains?(description_lower, ["spawn", "create"]) ->
        {:ok, spawner_behavior(description),
         %{type: :spawner, capabilities: [:spawn_child],
           description: description}}
      
      true ->
        # Default: create a simple logger behavior
        {:ok, logger_behavior(description),
         %{type: :logger, capabilities: [:log],
           description: description}}
    end
  end
  
  defp spawner_behavior(_description) do
    fn id, state, msg ->
      case msg do
        {:spawn_child, child_name} ->
          {:ok, pid, child_id} = Universal.spawn_universal(child_name)
          IO.puts("[#{id}] Spawned child: #{child_id} (#{inspect(pid)})")
          children = Map.get(state, :children, [])
          {:continue, Map.put(state, :children, [{child_id, pid} | children])}
        
        {:list_children, from} ->
          children = Map.get(state, :children, [])
          send(from, {:children, children})
          {:continue, state}
        
        _ ->
          {:continue, state}
      end
    end
  end
  
  defp logger_behavior(description) do
    fn id, state, msg ->
      count = Map.get(state, :message_count, 0)
      IO.puts("[#{id}] (#{description}) Message ##{count + 1}: #{inspect(msg, limit: 5)}")
      {:continue, Map.put(state, :message_count, count + 1)}
    end
  end
end