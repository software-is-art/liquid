defmodule BehaviorRuntime do
  @moduledoc """
  Protocol for pluggable behavior runtimes.

  This allows Universal servers to run behaviors implemented in different
  environments (e.g., BEAM functions, WASM, remote services) behind a common
  adapter.
  """

  @type runtime_ref :: any()
  @type metadata :: map()

  @callback init(opts :: keyword()) :: {:ok, runtime_ref(), metadata()} | {:error, term()}
  @callback handle(runtime_ref(), id :: atom(), state :: map(), msg :: term()) ::
              {:continue, state :: map(), runtime_ref()}
              | {:become, new_runtime_ref :: runtime_ref(), state :: map()}
  @callback describe(runtime_ref()) :: metadata()
  @callback terminate(runtime_ref()) :: :ok

  defmacro __using__(_opts) do
    quote do
      @behaviour BehaviorRuntime
    end
  end
end

