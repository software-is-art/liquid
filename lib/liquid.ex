defmodule Liquid do
  @moduledoc """
  Liquid Architecture - Universal Servers Through Conversation
  
  A system that transforms through natural language. No evolution, no waiting.
  You describe what you want, and the system reshapes itself immediately.
  """

  @doc """
  Start the liquid architecture system with conversation loop.
  """
  def start do
    Morpheus.start()
  end
  
  @doc """
  Spawn a new universal server.
  """
  def spawn_universal(id \\ nil) do
    Universal.spawn_universal(id)
  end
  
  @doc """
  Watch a process to see its message flow.
  """
  def watch(pid_or_name) do
    Observer.watch(pid_or_name)
  end
  
  @doc """
  Get current system context.
  """
  def context do
    Context.gather_full_context()
  end
  
  @doc """
  Show what's in the registry.
  """
  def registry do
    LiquidRegistry.get_context()
  end
end
