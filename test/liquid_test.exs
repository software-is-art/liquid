defmodule LiquidTest do
  use ExUnit.Case
  
  test "spawns universal server" do
    {:ok, pid, id} = Universal.spawn_universal()
    assert is_pid(pid)
    assert is_atom(id)
    assert Process.alive?(pid)
  end
  
  test "universal server accepts become message" do
    {:ok, pid, _id} = Universal.spawn_universal()
    
    test_behavior = fn _id, state, _msg ->
      {:continue, state}
    end
    
    send(pid, {:become, test_behavior})
    Process.sleep(10)
    assert Process.alive?(pid)
  end
  
  test "registry initialization" do
    table = LiquidRegistry.init()
    assert is_atom(table) or is_reference(table)
  end
  
  test "context building returns map" do
    context = Context.build_minimal_context("test")
    assert is_map(context)
  end
end
