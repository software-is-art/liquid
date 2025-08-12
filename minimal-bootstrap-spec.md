# Minimal Bootstrap: Universal Servers Through Conversation

## Core Concept

Joe Armstrong's Universal Server was a process that could become anything by receiving code. This spec takes it further: Universal Servers that transform through **natural language conversation**, with AI as the transformation engine.

No evolution. No waiting. You describe what you want, and the system reshapes itself immediately.

---

## Philosophy

Traditional software development:
1. Write code → Compile → Deploy → Run

Liquid architecture:
1. Speak intent → AI transforms servers → Already running

The system doesn't evolve; it **transforms**. Like a fluid that instantly takes the shape of whatever container you describe.

---

## Minimal Dependencies

```elixir
# mix.exs
defp deps do
  [
    # Absolute minimum
    {:req, "~> 0.4"},      # HTTP client for AI APIs
    {:jason, "~> 1.4"}     # JSON parsing
    
    # That's it. Everything else we build.
  ]
end
```

Why so minimal?
- Every dependency is a constraint on transformation
- The system should discover its own patterns
- We want to see what emerges from pure conversation

---

## The Universal Server (Next Level)

```elixir
defmodule Universal do
  @moduledoc """
  A server that becomes anything through conversation.
  Not evolution. Transformation.
  """
  
  def spawn_universal(id \\ nil) do
    id = id || generate_id()
    pid = spawn(fn -> universal_loop(id, %{}, &default_behavior/3) end)
    Process.register(pid, id)
    {:ok, pid, id}
  end
  
  defp universal_loop(id, state, behavior) do
    receive do
      {:become, new_behavior} when is_function(new_behavior, 3) ->
        # Instant transformation
        universal_loop(id, state, new_behavior)
      
      {:transform_via_ai, description} ->
        # Natural language transformation
        case AI.description_to_behavior(description) do
          {:ok, new_behavior} ->
            universal_loop(id, state, new_behavior)
          _ ->
            universal_loop(id, state, behavior)
        end
      
      msg ->
        # Current behavior handles everything else
        case behavior.(id, state, msg) do
          {:continue, new_state} ->
            universal_loop(id, new_state, behavior)
          {:become, new_behavior, new_state} ->
            universal_loop(id, new_state, new_behavior)
        end
    end
  end
  
  defp default_behavior(_id, state, _msg) do
    # Does nothing until told to become something
    {:continue, state}
  end
end
```

---

## Bootstrap Sequence

### Day 0: Primordial System
```elixir
# Just this. Nothing else.
{:ok, pid, id} = Universal.spawn_universal(:prime)
```

### Hour 1: First Transformation
```
Human: "Make this process count messages"
System: [Transforms prime into a counter]
```

### Hour 2: Network Effect
```
Human: "Create 10 more servers"
System: [Prime spawns 10 siblings]

### Hour 3: Communication Emerges
```
Human: "Make them talk to each other"
System: [Servers discover message passing patterns]
```

### Hour 6: Web Interface Appears
```
Human: "I want to see what's happening in a browser"
System: [Builds minimal HTTP server from scratch using :gen_tcp]
```

### Hour 24: The System Builds Itself
```
Human: "Can you manage yourself now?"
System: [Creates supervisory patterns, self-monitoring, self-healing]
```

---

## AI Integration Layer

```elixir
defmodule AI do
  @moduledoc """
  Translates human intent into server transformations.
  This is the only external dependency point.
  """
  
  def description_to_behavior(description) do
    prompt = """
    Generate an Elixir function that implements: #{description}
    
    The function signature must be: function(id, state, message)
    It must return either:
    - {:continue, new_state}
    - {:become, new_behavior_fn, new_state}
    
    Generate ONLY the function code, no explanations.
    """
    
    case request_ai(prompt) do
      {:ok, code_string} ->
        safe_compile(code_string)
      error ->
        error
    end
  end
  
  defp request_ai(prompt) do
    # Minimal HTTP call to AI service
    Req.post!("https://api.anthropic.com/v1/messages",
      json: %{
        model: "claude-3-opus-20240229",
        messages: [%{role: "user", content: prompt}],
        system: "You generate Elixir code for Universal Servers."
      },
      headers: [
        {"x-api-key", System.get_env("ANTHROPIC_API_KEY")},
        {"anthropic-version", "2023-06-01"}
      ]
    )
    |> then(fn %{body: body} ->
      {:ok, body["content"][0]["text"]}
    end)
  end
  
  defp safe_compile(code_string) do
    # Basic sandboxing - just enough to be safe
    with {:ok, ast} <- Code.string_to_quoted(code_string),
         :ok <- verify_safety(ast),
         {fun, _} <- Code.eval_quoted(ast) do
      {:ok, fun}
    end
  end
end
```

---

## Conversational Transformation Patterns

### Pattern 1: Direct Transformation
```
Human: "Make this a key-value store"
AI: [Generates behavior function for KV operations]
Server: [Instantly becomes KV store]
```

### Pattern 2: Behavioral Composition
```
Human: "Add caching to the KV store"
AI: [Wraps existing behavior with cache layer]
Server: [Now has both behaviors composed]
```

### Pattern 3: Spawning Networks
```
Human: "Create a distributed cache with 5 nodes"
AI: [Current server spawns 5 new ones with cache behavior]
Servers: [Self-organize into distributed cache]
```

### Pattern 4: Protocol Discovery
```
Human: "Make them coordinate without losing data"
AI: [Generates consensus protocol]
Servers: [Implement generated protocol]
```

---

## Context Mechanism: How AI Understands the System

The AI needs to understand what exists to make intelligent transformations. Here's how, without frameworks:

### Self-Describing Behaviors

Every behavior the AI generates includes self-description:

```elixir
defmodule Universal do
  defp universal_loop(id, state, behavior, metadata \\ %{}) do
    receive do
      {:describe_self, caller, ref} ->
        # Every server can explain what it is
        send(caller, {ref, metadata})
        universal_loop(id, state, behavior, metadata)
      
      {:transform_via_ai, description} ->
        # Build context only as needed
        context = build_minimal_context(description)
        
        # AI generates self-describing behavior
        {:ok, new_behavior, new_meta} = AI.transform(description, context, id)
        
        # Behavior now includes its own documentation
        universal_loop(id, state, new_behavior, new_meta)
      
      msg ->
        # Normal behavior
        case behavior.(id, state, msg) do
          {:continue, new_state} ->
            universal_loop(id, new_state, behavior, metadata)
        end
    end
  end
end
```

### Progressive Context Building

Don't query everything - be smart about what you need:

```elixir
defmodule Context do
  @moduledoc """
  Minimal context gathering. No frameworks needed.
  """
  
  def build_minimal_context(description) do
    # Parse what the user is asking for
    cond do
      String.contains?(description, "connect") ->
        # Need to know what exists to connect
        gather_process_list()
      
      String.contains?(description, "all") ->
        # Full system scan needed
        gather_full_context()
      
      true ->
        # Creating something new, no context needed
        %{}
    end
  end
  
  def gather_process_list do
    # Non-blocking, parallel queries
    Process.list()
    |> Enum.map(fn pid ->
      Task.async(fn ->
        ref = make_ref()
        send(pid, {:describe_self, self(), ref})
        
        receive do
          {^ref, metadata} -> {pid, metadata}
        after
          50 -> {pid, :no_response}  # 50ms timeout
        end
      end)
    end)
    |> Enum.map(&Task.await(&1, 100))
    |> Enum.reject(fn {_, meta} -> meta == :no_response end)
    |> Map.new()
  end
end
```

### Lazy Registration

Processes announce themselves only when they transform:

```elixir
defmodule Registry do
  @moduledoc """
  Simplest possible registry. Just ETS.
  """
  
  def init do
    :ets.new(:registry, [:set, :public, :named_table])
  end
  
  def announce(id, metadata) do
    # Lazy registration - only when something interesting happens
    :ets.insert(:registry, {id, metadata, System.os_time()})
  end
  
  def get_context do
    # Fast lookup, no message passing needed
    :ets.tab2list(:registry)
    |> Enum.map(fn {id, meta, _time} -> 
      %{id: id, type: meta[:type], capabilities: meta[:capabilities]}
    end)
  end
end
```

### AI Context Integration

The AI generates behaviors that maintain their own context:

```elixir
defmodule AI do
  def transform(description, context, server_id) do
    prompt = """
    Current context: #{inspect(context, pretty: true)}
    Transform server #{server_id} to: #{description}
    
    Generate a behavior function that:
    1. Implements: #{description}
    2. Includes metadata about what it does
    
    Return both the function and metadata:
    
    behavior = fn id, state, msg -> ... end
    metadata = %{
      type: :cache,  # or :database, :worker, etc
      capabilities: [:get, :put],  # what messages it handles
      description: "LRU cache with 1000 item limit"
    }
    """
    
    case request_ai(prompt) do
      {:ok, code} ->
        {behavior, metadata} = safe_eval(code)
        {:ok, behavior, metadata}
    end
  end
end
```

### Example Context Flow

```
Human: "Create a cache"
System: [No context needed, creates cache with self-description]

Human: "Connect it to the database"
System: [Queries context to find database, wires them together]

Human: "Show me all processes"
System: [Full context scan, returns process list with descriptions]
```

---

## What We're NOT Building

- **No web framework** - Let servers discover HTTP when needed
- **No database** - Let servers invent persistence when required  
- **No supervisor trees** - Let reliability patterns emerge from need
- **No GenServer** - Raw processes until abstraction is necessary
- **No predetermined architecture** - Architecture emerges from conversation

---

## Bootstrap Implementation

### `lib/morpheus.ex`
```elixir
defmodule Morpheus do
  @moduledoc """
  The minimal bootstrap. Just enough to begin.
  """
  
  def start do
    # Birth of the first Universal Server
    {:ok, prime_pid, :prime} = Universal.spawn_universal(:prime)
    
    # The conversation loop
    loop(prime_pid)
  end
  
  defp loop(prime_pid) do
    IO.write("> ")
    input = IO.gets("") |> String.trim()
    
    case input do
      "exit" -> 
        :ok
      
      description ->
        # Transform through conversation
        send(prime_pid, {:transform_via_ai, description})
        
        # Give it a moment to transform
        Process.sleep(100)
        
        # Continue conversation
        loop(prime_pid)
    end
  end
end
```

### Starting the System
```bash
# Terminal 1: Start the system
$ iex -S mix
iex> Morpheus.start()
> make this count messages
[Prime transforms into counter]
> spawn 5 workers
[Prime creates 5 worker processes]
> make the workers do parallel computation
[Workers transform into compute nodes]
```

---

## Observation Without Frameworks

Since we have no frameworks, how do we observe the system?

```elixir
defmodule Observer do
  @moduledoc """
  Minimal observation. Built from nothing.
  """
  
  def watch(pid) do
    # Just print what a process is doing
    :erlang.trace(pid, true, [:receive, :send])
    
    receive_loop()
  end
  
  defp receive_loop do
    receive do
      trace_msg ->
        IO.inspect(trace_msg, label: "TRACE")
        receive_loop()
    end
  end
end
```

Later, the system can build its own visualization:
```
Human: "Show me a web view of all processes"
System: [Builds HTTP server, generates HTML, serves process graph]
```

---

## Success Criteria

1. **Time to first behavior**: < 2 seconds from description
2. **Zero predetermined structure**: No architecture until requested
3. **Self-hosting speed**: System can modify itself within 1 hour
4. **Pattern discovery**: Invents its own abstractions within 24 hours
5. **Framework emergence**: Builds equivalent of Phoenix when needed (not before)

---

## The Radical Premise

Most systems are built on layers of decisions made by others. This system makes its own decisions through conversation.

Start with almost nothing. Speak it into existence. Watch it build itself.

Not evolution. Not frameworks. Just **pure transformation through dialogue**.

---

## First Week Milestones

- **Day 1**: Basic transformations working (counter, storage, messaging)
- **Day 2**: Multi-process coordination emerges
- **Day 3**: System invents its own supervision patterns
- **Day 4**: HTTP/WebSocket servers built from :gen_tcp
- **Day 5**: Distributed communication patterns discovered
- **Day 6**: System can modify its own code
- **Day 7**: Full self-hosting: system can rebuild itself

---

## The Question This Answers

*"What's the minimum code needed for a system that can build anything through conversation?"*

Answer: One Universal Server + AI translator + conversation loop ≈ 100 lines of code.

Everything else emerges from dialogue.