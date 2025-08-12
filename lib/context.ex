defmodule Context do
  @moduledoc """
  Minimal context gathering. No frameworks needed.
  """
  
  def build_minimal_context(description) do
    # Parse what the user is asking for
    cond do
      String.contains?(description, ["connect", "talk", "communicate"]) ->
        # Need to know what exists to connect
        gather_process_list()
      
      String.contains?(description, ["all", "every", "system"]) ->
        # Full system scan needed
        gather_full_context()
      
      String.contains?(description, ["spawn", "create"]) ->
        # Limited context - just count of existing processes
        %{process_count: length(Process.list())}
      
      true ->
        # Creating something new, no context needed
        %{}
    end
  end
  
  def gather_process_list do
    # Non-blocking, parallel queries
    registered = Process.registered()
    
    registered
    |> Enum.map(fn name ->
      Task.async(fn ->
        case Process.whereis(name) do
          nil -> {name, :not_found}
          pid -> query_process(pid, name)
        end
      end)
    end)
    |> Enum.map(&Task.await(&1, 100))
    |> Enum.reject(fn {_, meta} -> meta == :no_response or meta == :not_found end)
    |> Map.new()
  end
  
  def gather_full_context do
    process_list = gather_process_list()
    
    %{
      processes: process_list,
      process_count: length(Process.list()),
      registered_count: length(Process.registered()),
      system_time: System.os_time(:millisecond)
    }
  end
  
  defp query_process(pid, name) do
    ref = make_ref()
    send(pid, {:describe_self, self(), ref})
    
    receive do
      {^ref, metadata} -> {name, metadata}
    after
      50 -> {name, :no_response}  # 50ms timeout
    end
  end
end