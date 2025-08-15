# Liquid Architecture

Universal Servers Through Conversation - A radical approach to system architecture where servers transform instantly through natural language.

## Quick Start

```bash
# Start development shell
devbox shell

# Install dependencies
mix deps.get

# Start interactive Elixir
iex -S mix

# Start the liquid system
Liquid.start()
```

## Basic Usage (Without AI)

Test the system with pre-built behaviors:

```elixir
# In iex
iex> {:ok, pid, id} = Universal.spawn_universal(:worker1)
iex> Examples.transform_with(:worker1, :counter)
iex> send(:worker1, :increment)
iex> send(:worker1, :increment)
iex> send(:worker1, :decrement)

# Spawn multiple servers
iex> Universal.spawn_universal(:cache)
iex> Universal.spawn_universal(:db)
iex> Examples.transform_with(:cache, :accumulator)
iex> Examples.transform_with(:db, :echo)

# Use them
iex> send(:cache, {:add, "item1"})
iex> send(:cache, {:add, "item2"})
iex> send(:db, {:echo, "Hello", self()})
iex> flush()  # See messages
```

## AI Transformations

The system supports multiple AI backends:

### Codex CLI
```bash
# Works if you have `codex` installed
iex> Liquid.start()
> backends  # Check available backends
```

### Ollama (Free, Local)
```bash
# Install Ollama
brew install ollama
ollama pull codellama

# Start Ollama
ollama serve
```

### Anthropic API
```bash
export ANTHROPIC_API_KEY=your_api_key_here
```

### Using the System

```elixir
iex> Liquid.start()

> backends        # Show available AI backends
> use mock        # Switch to mock backend (no AI needed)
> use codex      # Use Codex CLI
> use ollama      # Use local Ollama
> make this count messages
> spawn 5 workers
> make them echo what they receive
```

## System Observation

```elixir
# Watch a process
iex> Observer.watch(:prime)

# Get system context
iex> Liquid.context()

# See registry
iex> Liquid.registry()
```

## Architecture

The system consists of:

1. **Universal Servers** - Processes that can become anything
2. **AI Layer** - Translates natural language to behaviors
3. **Context System** - Minimal, lazy context gathering
4. **Registry** - Simple ETS-based tracking
5. **Safe Compiler** - Sandboxed code evaluation

## Philosophy

- No frameworks until needed
- Let patterns emerge from conversation
- Transform, don't evolve
- Minimal dependencies (just HTTP client)

## Security Note

The SafeCompiler module prevents dangerous operations but this is experimental software. Use with caution.
