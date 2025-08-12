defmodule Morpheus do
  @moduledoc """
  The minimal bootstrap. Just enough to begin.
  """
  
  def start do
    IO.puts("\n🌊 Liquid Architecture System")
    IO.puts("━━━━━━━━━━━━━━━━━━━━━━━━━━")
    IO.puts("Starting with primordial Universal Server...\n")
    
    # Initialize registry
    LiquidRegistry.init()
    
    # Birth of the first Universal Server
    {:ok, prime_pid, :prime} = Universal.spawn_universal(:prime)
    
    IO.puts("✓ Prime server spawned (pid: #{inspect(prime_pid)})")
    IO.puts("\nSpeak your intent. The system will transform.\n")
    IO.puts("Commands:")
    IO.puts("  'exit' - Stop the system")
    IO.puts("  'status' - Show system status")
    IO.puts("  'list' - List all processes")
    IO.puts("  'backends' - Show available AI backends")
    IO.puts("  'use <backend>' - Switch AI backend (mock/ollama/claude_code/api)\n")
    
    # The conversation loop
    loop(prime_pid)
  end
  
  defp loop(prime_pid) do
    IO.write("> ")
    input = IO.gets("") |> String.trim()
    
    case String.downcase(input) do
      "exit" -> 
        IO.puts("\n👋 Shutting down liquid architecture...")
        :ok
      
      "status" ->
        show_status()
        loop(prime_pid)
      
      "list" ->
        show_processes()
        loop(prime_pid)
      
      "backends" ->
        show_backends()
        loop(prime_pid)
      
      "" ->
        loop(prime_pid)
      
      description ->
        # Check for "use <backend>" command
        case String.split(description, " ", parts: 2) do
          ["use", backend] ->
            switch_backend(String.to_atom(backend))
            loop(prime_pid)
          
          _ ->
            # Transform through conversation
            IO.puts("\n🔄 Transforming: #{description}")
        
        send(prime_pid, {:transform_via_ai, description, self()})
        
        # Wait for transformation result
        receive do
          {:transformed, id} ->
            IO.puts("✓ Server #{id} transformed successfully")
          {:transform_failed, id, reason} ->
            IO.puts("✗ Transformation failed for #{id}: #{inspect(reason)}")
        after
          5000 ->
            IO.puts("⏱ Transformation timeout")
        end
        
        # Continue conversation
        loop(prime_pid)
        end  # Close the inner case
    end
  end
  
  defp show_backends do
    backends = AI.available_backends()
    current = Application.get_env(:liquid, :ai_backend, :auto)
    
    IO.puts("\n═══ AI Backends ═══")
    IO.puts("Current: #{current}")
    IO.puts("\nAvailable:")
    
    if :claude_code in backends do
      IO.puts("  • claude_code - Claude Code CLI (your subscription)")
    end
    
    if :ollama in backends do
      IO.puts("  • ollama - Local Ollama instance")
    end
    
    if :anthropic_api in backends do
      IO.puts("  • api - Anthropic API (requires key)")
    end
    
    IO.puts("  • mock - Mock behaviors (always available)")
    
    if length(backends) == 1 and :mock in backends do
      IO.puts("\n💡 Tip: Install Ollama or set ANTHROPIC_API_KEY for AI transformations")
    end
    IO.puts("")
  end
  
  defp switch_backend(backend) do
    case AI.set_backend(backend) do
      {:ok, new_backend} ->
        IO.puts("✓ Switched to #{new_backend} backend")
      {:error, reason} ->
        IO.puts("✗ Failed to switch backend: #{reason}")
    end
  end
  
  defp show_status do
    process_count = length(Process.list())
    registered_count = length(Process.registered())
    context = LiquidRegistry.get_context()
    
    IO.puts("\n═══ System Status ═══")
    IO.puts("Processes: #{process_count}")
    IO.puts("Registered: #{registered_count}")
    IO.puts("In Registry: #{length(context)}")
    
    if length(context) > 0 do
      IO.puts("\nRegistry Contents:")
      Enum.each(context, fn entry ->
        IO.puts("  • #{entry.id} (#{entry.type}): #{entry.description}")
        if length(entry.capabilities) > 0 do
          IO.puts("    Capabilities: #{Enum.join(entry.capabilities, ", ")}")
        end
      end)
    end
    IO.puts("")
  end
  
  defp show_processes do
    registered = Process.registered()
    
    IO.puts("\n═══ Registered Processes ═══")
    Enum.each(registered, fn name ->
      pid = Process.whereis(name)
      if pid do
        IO.puts("  • #{name}: #{inspect(pid)}")
      end
    end)
    IO.puts("")
  end
end