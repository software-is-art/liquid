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

  def architect_behavior do
    fn id, state, msg ->
      case msg do
        {:goal, description} when is_binary(description) ->
          LiquidRegistry.log(id, :goal_received, %{description: description})

          case Capabilities.execute(:ai_transform, description, id) do
            {:ok, {behavior, metadata}} ->
              # Default to minimal capabilities if missing
              md = Map.merge(%{type: :worker, capabilities: [], description: description}, Map.new(metadata))
              _ = LiquidRegistry.log(id, :capability_used, %{op: :ai_transform})
              # Apply to self by default
              :ok = Capabilities.execute(:apply_transform, %{target: id, behavior: behavior, metadata: md}, id)
              _ = LiquidRegistry.log(id, :capability_used, %{op: :apply_transform})
              {:continue, state}

            {:ok, behavior} when is_function(behavior, 3) ->
              md = %{type: :worker, capabilities: [], description: description}
              :ok = Capabilities.execute(:apply_transform, %{target: id, behavior: behavior, metadata: md}, id)
              _ = LiquidRegistry.log(id, :capability_used, %{op: :apply_transform})
              {:continue, state}

            {:error, reason} ->
              IO.puts("[#{id}] Architect synth failed: #{inspect(reason)}")
              {:continue, state}
          end

        {:goal, description, from} when is_binary(description) and is_pid(from) ->
          LiquidRegistry.log(id, :goal_received, %{description: description})

          result =
            case Capabilities.execute(:ai_transform, description, id) do
              {:ok, {behavior, metadata}} ->
                md = Map.merge(%{type: :worker, capabilities: [], description: description}, Map.new(metadata))
                _ = LiquidRegistry.log(id, :capability_used, %{op: :ai_transform})
                :ok = Capabilities.execute(:apply_transform, %{target: id, behavior: behavior, metadata: md}, id)
                _ = LiquidRegistry.log(id, :capability_used, %{op: :apply_transform})
                {:ok, %{target: id, description: description}}

              {:ok, behavior} when is_function(behavior, 3) ->
                md = %{type: :worker, capabilities: [], description: description}
                :ok = Capabilities.execute(:apply_transform, %{target: id, behavior: behavior, metadata: md}, id)
                _ = LiquidRegistry.log(id, :capability_used, %{op: :apply_transform})
                {:ok, %{target: id, description: description}}

              {:error, reason} -> {:error, reason}
            end

          send(from, {:architect_applied, result})
          {:continue, state}

        {:apply_to, target, description} when is_atom(target) and is_binary(description) ->
          case Capabilities.execute(:ai_transform, description, id) do
            {:ok, {behavior, metadata}} ->
              md = Map.merge(%{type: :worker, capabilities: [], description: description}, Map.new(metadata))
              :ok = Capabilities.execute(:apply_transform, %{target: target, behavior: behavior, metadata: md}, id)
              _ = LiquidRegistry.log(id, :capability_used, %{op: :apply_transform})
              {:continue, state}
            {:error, reason} ->
              IO.puts("[#{id}] Architect apply_to failed: #{inspect(reason)}")
              {:continue, state}
          end

        {:apply_to, target, description, from}
            when (is_atom(target) or is_pid(target)) and is_binary(description) and is_pid(from) ->
          result =
            case Capabilities.execute(:ai_transform, description, id) do
              {:ok, {behavior, metadata}} ->
                md = Map.merge(%{type: :worker, capabilities: [], description: description}, Map.new(metadata))
                :ok = Capabilities.execute(:apply_transform, %{target: target, behavior: behavior, metadata: md}, id)
                _ = LiquidRegistry.log(id, :capability_used, %{op: :apply_transform})
                {:ok, %{target: target, description: description}}
              {:error, reason} -> {:error, reason}
            end
          send(from, {:architect_applied, result})
          {:continue, state}

        {:make_architect, target} when is_atom(target) or is_pid(target) ->
          behavior = Examples.architect_behavior()
          md = metadata_for(:architect, "System architect")
          :ok = Capabilities.execute(:apply_transform, %{target: target, behavior: behavior, metadata: md}, id)
          _ = LiquidRegistry.log(id, :capability_used, %{op: :apply_transform, target: target, role: :architect})
          {:continue, state}

        {:spawn_architect, name} when is_atom(name) ->
          case Capabilities.execute(:spawn_child, name, id) do
            {:ok, _pid, child_id} ->
              behavior = Examples.architect_behavior()
              md = metadata_for(:architect, "System architect")
              :ok = Capabilities.execute(:apply_transform, %{target: child_id, behavior: behavior, metadata: md}, id)
              _ = LiquidRegistry.log(id, :capability_used, %{op: :apply_transform, target: child_id, role: :architect})
              {:continue, state}
            other ->
              IO.puts("[#{id}] spawn_architect failed: #{inspect(other)}")
              {:continue, state}
          end

        {:get_registry, from} ->
          res = Capabilities.execute(:get_registry, nil, id)
          _ = LiquidRegistry.log(id, :capability_used, %{op: :get_registry})
          send(from, {:registry, res})
          {:continue, state}

        {:get_context, from} ->
          res = Capabilities.execute(:get_context, nil, id)
          _ = LiquidRegistry.log(id, :capability_used, %{op: :get_context})
          send(from, {:context, res})
          {:continue, state}

        _ ->
          {:continue, state}
      end
    end
  end

  def mediated_spawner_behavior do
    fn id, state, msg ->
      children = Map.get(state, :children, [])
      case msg do
        {:spawn_via_cap, child_name} when is_atom(child_name) ->
          send(id, {:capability, :spawn_child, child_name, self()})
          {:continue, state}

        {:capability_result, ^id, :spawn_child, {:ok, _pid, child_id}} ->
          {:continue, %{children: [{child_id} | children]}}

        {:list_children, from} ->
          send(from, {:children, Enum.map(children, fn {c} -> c end)})
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
    send_to_process(pid_or_name, {:become, counter_behavior(), metadata_for(:counter, "Message counter")})
  end
  
  def transform_with(pid_or_name, :echo) do
    send_to_process(pid_or_name, {:become, echo_behavior(), metadata_for(:echo, "Echo server")})
  end
  
  def transform_with(pid_or_name, :accumulator) do
    send_to_process(pid_or_name, {:become, accumulator_behavior(), metadata_for(:accumulator, "Item accumulator")})
  end
  
  def transform_with(pid_or_name, :worker) do
    send_to_process(pid_or_name, {:become, worker_behavior(), metadata_for(:worker, "Task worker")})
  end

  def transform_with(pid_or_name, :mediated_spawner) do
    send_to_process(pid_or_name, {:become, mediated_spawner_behavior(), metadata_for(:mediated_spawner, "Spawner via capability mediator")})
  end

  def transform_with(pid_or_name, :architect) do
    send_to_process(pid_or_name, {:become, architect_behavior(), metadata_for(:architect, "System architect")})
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

    LiquidRegistry.announce(id, metadata_for(type, description))
  end
  
  defp capabilities_for(:counter), do: [:increment, :decrement, :get]
  defp capabilities_for(:echo), do: [:echo]
  defp capabilities_for(:accumulator), do: [:add, :get_all, :clear]
  defp capabilities_for(:worker), do: [:work]
  defp capabilities_for(:mediated_spawner), do: [:spawn_child]
  defp capabilities_for(:architect), do: [:get_context, :get_registry, :get_history, :ai_transform, :apply_transform, :spawn_child]

  defp metadata_for(type, description) do
    %{
      type: type,
      capabilities: capabilities_for(type),
      description: description
    }
  end
end
