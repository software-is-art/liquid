defmodule Examples do
  @moduledoc """
  Example behaviors for testing the liquid architecture without AI.
  """
  
  def counter_behavior do
    fn id, state, msg ->
      count = Map.get(state, :count, 0)
      
      case msg do
        :increment ->
          new_count = count + 1
          IO.puts("[#{id}] Count: #{new_count}")
          {:continue, %{count: new_count}}
        
        :decrement ->
          new_count = count - 1
          IO.puts("[#{id}] Count: #{new_count}")
          {:continue, %{count: new_count}}
        
        {:get, from} ->
          send(from, {:count, count})
          {:continue, state}
        
        _ ->
          {:continue, state}
      end
    end
  end
  
  def echo_behavior do
    fn id, state, msg ->
      case msg do
        {:echo, text, from} ->
          IO.puts("[#{id}] Echoing: #{text}")
          send(from, {:echoed, text})
          {:continue, state}
        
        _ ->
          {:continue, state}
      end
    end
  end
  
  def accumulator_behavior do
    fn id, state, msg ->
      list = Map.get(state, :items, [])
      
      case msg do
        {:add, item} ->
          new_list = [item | list]
          IO.puts("[#{id}] Added #{inspect(item)}. Total items: #{length(new_list)}")
          {:continue, %{items: new_list}}
        
        {:get_all, from} ->
          send(from, {:items, Enum.reverse(list)})
          {:continue, state}
        
        :clear ->
          IO.puts("[#{id}] Cleared all items")
          {:continue, %{items: []}}
        
        _ ->
          {:continue, state}
      end
    end
  end
  
  def worker_behavior do
    fn id, state, msg ->
      case msg do
        {:work, task, from} ->
          IO.puts("[#{id}] Working on: #{task}")
          # Simulate work
          Process.sleep(100)
          result = "Completed: #{task}"
          send(from, {:result, result})
          {:continue, state}
        
        _ ->
          {:continue, state}
      end
    end
  end
  
  @doc """
  Transform a universal server with a pre-built behavior
  """
  def transform_with(pid_or_name, :counter) do
    send_to_process(pid_or_name, {:become, counter_behavior()})
    announce_to_registry(pid_or_name, :counter, "Message counter")
  end
  
  def transform_with(pid_or_name, :echo) do
    send_to_process(pid_or_name, {:become, echo_behavior()})
    announce_to_registry(pid_or_name, :echo, "Echo server")
  end
  
  def transform_with(pid_or_name, :accumulator) do
    send_to_process(pid_or_name, {:become, accumulator_behavior()})
    announce_to_registry(pid_or_name, :accumulator, "Item accumulator")
  end
  
  def transform_with(pid_or_name, :worker) do
    send_to_process(pid_or_name, {:become, worker_behavior()})
    announce_to_registry(pid_or_name, :worker, "Task worker")
  end
  
  defp send_to_process(pid, msg) when is_pid(pid) do
    send(pid, msg)
  end
  
  defp send_to_process(name, msg) when is_atom(name) do
    case Process.whereis(name) do
      nil -> {:error, :not_found}
      pid -> send(pid, msg)
    end
  end
  
  defp announce_to_registry(pid_or_name, type, description) do
    id = if is_pid(pid_or_name), do: pid_or_name, else: pid_or_name
    
    metadata = %{
      type: type,
      capabilities: capabilities_for(type),
      description: description
    }
    
    LiquidRegistry.announce(id, metadata)
  end
  
  defp capabilities_for(:counter), do: [:increment, :decrement, :get]
  defp capabilities_for(:echo), do: [:echo]
  defp capabilities_for(:accumulator), do: [:add, :get_all, :clear]
  defp capabilities_for(:worker), do: [:work]
end