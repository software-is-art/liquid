defmodule AIFLowTest do
  use ExUnit.Case

  setup do
    LiquidRegistry.init()
    # Force tests to use the mock backend for determinism
    Application.put_env(:liquid, :ai_backend, :mock)
    :ok
  end

  test "AI.Mock transform to counter and increments state" do
    {:ok, pid, id} = Universal.spawn_universal()
    send(pid, {:transform_via_ai, "make it count", self()})
    assert_receive {:transformed, ^id}, 1000

    send(pid, :increment)
    send(pid, :increment)

    ref = make_ref()
    send(pid, {:get_state, self(), ref})
    assert_receive {^ref, %{count: 2}}, 500
  end

  test "capability usage is logged when allowed" do
    {:ok, pid, id} = Universal.spawn_universal(:cap_test)
    Examples.transform_with(:cap_test, :mediated_spawner)

    send(:cap_test, {:spawn_via_cap, :child_one})

    # Allow the capability to be processed
    Process.sleep(50)

    events = LiquidRegistry.get_recent(10)
    assert Enum.any?(events, fn
             {^id, _ts, :capability_used, %{op: :spawn_child}} -> true
             _ -> false
           end)
  end

  test "SafeCompiler forbids direct side effects" do
    assert {:error, _} = SafeCompiler.compile("IO.puts(\"hi\")")
    assert {:error, _} = SafeCompiler.compile(":erlang.spawn(fn -> :ok end)")
    assert {:error, _} = SafeCompiler.compile("Universal.spawn_universal(:x)")
  end
end
