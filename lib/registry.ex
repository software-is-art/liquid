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
    case :ets.info(:liquid_history) do
      :undefined ->
        :ets.new(:liquid_history, [:bag, :public, :named_table])
      _ ->
        :liquid_history
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

  @doc """
  Append an event to history with timestamp.
  """
  def log(id, event, data) do
    ts = System.os_time(:millisecond)
    init()
    :ets.insert(:liquid_history, {id, ts, event, data})
  end

  @doc """
  Get the most recent `n` events across all ids.
  """
  def get_recent(n \\ 50) do
    init()
    :ets.tab2list(:liquid_history)
    |> Enum.sort_by(fn {_id, ts, _event, _data} -> ts end, :desc)
    |> Enum.take(n)
  end

  @doc """
  Get all events for a given id.
  """
  def get_by(id) do
    init()
    :ets.lookup(:liquid_history, id)
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
