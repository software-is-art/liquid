defmodule LiquidRegistry do
  @moduledoc """
  Simplest possible registry. Just ETS.
  """
  
  def init do
    case :ets.info(:liquid_registry) do
      :undefined ->
        :ets.new(:liquid_registry, [:set, :public, :named_table])
      _ ->
        :liquid_registry
    end
  end
  
  def announce(id, metadata) do
    # Lazy registration - only when something interesting happens
    :ets.insert(:liquid_registry, {id, metadata, System.os_time(:millisecond)})
  end
  
  def get_context do
    # Fast lookup, no message passing needed
    case :ets.info(:liquid_registry) do
      :undefined ->
        []
      _ ->
        :ets.tab2list(:liquid_registry)
        |> Enum.map(fn {id, meta, _time} -> 
          %{
            id: id, 
            type: Map.get(meta, :type, :unknown), 
            capabilities: Map.get(meta, :capabilities, []),
            description: Map.get(meta, :description, "")
          }
        end)
    end
  end
  
  def lookup(id) do
    case :ets.info(:liquid_registry) do
      :undefined ->
        nil
      _ ->
        case :ets.lookup(:liquid_registry, id) do
          [{^id, metadata, _time}] -> metadata
          [] -> nil
        end
    end
  end
end