defmodule Observer do
  @moduledoc """
  Minimal observation. Built from nothing.
  """
  
  def watch(pid) when is_pid(pid) do
    # Just print what a process is doing
    :erlang.trace(pid, true, [:receive, :send])
    
    IO.puts("Watching #{inspect(pid)}. Press Ctrl+C to stop.")
    receive_loop()
  end
  
  def watch(name) when is_atom(name) do
    case Process.whereis(name) do
      nil ->
        IO.puts("Process #{name} not found")
      pid ->
        watch(pid)
    end
  end
  
  defp receive_loop do
    receive do
      {:trace, pid, :receive, msg} ->
        IO.puts("[#{inspect(pid)}] ← #{inspect(msg, limit: 5)}")
        receive_loop()
      
      {:trace, pid, :send, msg, to} ->
        IO.puts("[#{inspect(pid)}] → [#{inspect(to)}]: #{inspect(msg, limit: 5)}")
        receive_loop()
      
      other ->
        IO.inspect(other, label: "TRACE")
        receive_loop()
    end
  end
  
  def stop_watching(pid) when is_pid(pid) do
    :erlang.trace(pid, false, [:receive, :send])
  end
  
  def stop_watching(name) when is_atom(name) do
    case Process.whereis(name) do
      nil -> :ok
      pid -> stop_watching(pid)
    end
  end
end