# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the Liquid Architecture project - a radical approach to system architecture where servers transform instantly through natural language conversation. It implements Universal Servers that can become anything through AI-powered transformations.

## Development Environment

### Setup
```bash
# Start development shell (required for Elixir/Erlang)
devbox shell

# Install dependencies
mix deps.get

# Start interactive Elixir REPL
iex -S mix
```

### Common Commands
```bash
# Run tests
mix test

# Format code
mix format

# Compile
mix compile

# Clean build artifacts
mix clean

# Update dependencies
mix deps.update --all
```

## Architecture

### Core Modules

- **`Universal`** (lib/universal.ex): The core Universal Server that can transform into anything via behavior functions
- **`Morpheus`** (lib/morpheus.ex): Main conversation loop and system bootstrap
- **`Liquid`** (lib/liquid.ex): High-level API for system interaction
- **`AI`** (lib/ai.ex): Flexible AI backend supporting multiple providers (Claude Code, Ollama, Anthropic API, Mock)
- **`Context`** (lib/context.ex): Minimal context gathering for AI transformations
- **`SafeCompiler`** (lib/safe_compiler.ex): Sandboxed code evaluation for AI-generated behaviors
- **`LiquidRegistry`** (lib/registry.ex): Simple ETS-based process registry
- **`Observer`** (lib/observer.ex): Process observation and tracing utilities

### AI Backends

The system supports multiple AI backends with automatic detection:
1. **Claude Code CLI** - Uses local Claude installation (highest priority)
2. **Ollama** - Local LLM instance (requires `ollama serve`)
3. **Anthropic API** - Cloud API (requires `ANTHROPIC_API_KEY`)
4. **Mock** - Pre-built behaviors for testing without AI

### Key Concepts

1. **Universal Servers**: Processes that can transform their behavior instantly through functions
2. **Behavior Functions**: Functions with signature `fn(id, state, msg) -> {:continue, new_state} | {:become, new_fn, new_state}`
3. **AI Transformations**: Natural language descriptions are converted to Elixir behavior functions
4. **Lazy Context**: Context is gathered only when needed for transformations
5. **Self-Describing Behaviors**: Each behavior includes metadata about its capabilities

## Working with the System

### Starting the System
```elixir
# In iex
Liquid.start()
# or
Morpheus.start()
```

### Basic Commands in the REPL
- `exit` - Stop the system
- `status` - Show system status
- `list` - List all processes
- `backends` - Show available AI backends
- `use <backend>` - Switch AI backend (mock/ollama/claude_code/api)

### Creating Transformations
When implementing AI transformations, ensure generated behaviors:
- Return `{:continue, new_state}` or `{:become, new_behavior_fn, new_state}`
- Include metadata with `type`, `capabilities`, and `description`
- Are pure functions without side effects in the transformation logic
- Handle messages appropriately for their described purpose

### Testing
Run tests with `mix test`. Tests are located in the `test/` directory.

## Philosophy

- **No frameworks until needed** - Let patterns emerge from conversation
- **Transform, don't evolve** - Instant transformation rather than gradual evolution
- **Minimal dependencies** - Only `req` for HTTP and core Elixir/OTP
- **Architecture emerges** - No predetermined structure, built through dialogue