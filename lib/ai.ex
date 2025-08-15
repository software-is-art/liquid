defmodule AI do
  @moduledoc """
  Flexible AI backend supporting multiple providers.
  Automatically detects and uses the best available option.
  """
  
  @doc """
  Transform a server using the best available AI backend.
  Priority: Codex CLI > Ollama > Anthropic API > Mock
  """
  def transform(description, context, server_id) do
    backend = detect_backend()
    
    IO.puts("🤖 Using AI backend: #{backend}")
    
    case backend do
      :codex ->
        AI.Codex.transform(description, context, server_id)

      :ollama ->
        AI.Ollama.transform(description, context, server_id)
      
      :anthropic_api ->
        transform_with_api(description, context, server_id)
      
      :mock ->
        IO.puts("   ⚠️  No AI backend available, using mock behaviors")
        AI.Mock.transform(description, context, server_id)
      
      :none ->
        {:error, "No AI backend available. Install Ollama or set ANTHROPIC_API_KEY"}
    end
  end
  
  @doc """
  Get information about available backends
  """
  def available_backends do
    [
      codex: AI.Codex.available?(),
      ollama: AI.Ollama.available?(),
      anthropic_api: api_available?(),
      mock: true
    ]
    |> Enum.filter(fn {_, available} -> available end)
    |> Enum.map(fn {backend, _} -> backend end)
  end
  
  @doc """
  Manually set the preferred backend
  """
  def set_backend(backend) when backend in [:codex, :ollama, :anthropic_api, :mock] do
    Application.put_env(:liquid, :ai_backend, backend)
    {:ok, backend}
  end
  
  def set_backend(_), do: {:error, "Invalid backend"}
  
  defp detect_backend do
    # Check for user preference
    case Application.get_env(:liquid, :ai_backend) do
      nil ->
        # Auto-detect based on availability
        cond do
          AI.Codex.available?() -> :codex
          AI.Ollama.available?() -> :ollama
          api_available?() -> :anthropic_api
          true -> :mock
        end
      
      backend ->
        # Use specified backend if available
        if backend_available?(backend) do
          backend
        else
          IO.puts("⚠️  Preferred backend #{backend} not available, auto-detecting...")
          detect_backend_without_preference()
        end
    end
  end
  
  defp detect_backend_without_preference do
    cond do
      AI.Codex.available?() -> :codex
      AI.Ollama.available?() -> :ollama
      api_available?() -> :anthropic_api
      true -> :mock
    end
  end
  
  defp backend_available?(:codex), do: AI.Codex.available?()
  defp backend_available?(:ollama), do: AI.Ollama.available?()
  defp backend_available?(:anthropic_api), do: api_available?()
  defp backend_available?(:mock), do: true
  defp backend_available?(_), do: false
  
  defp api_available? do
    api_key = System.get_env("ANTHROPIC_API_KEY")
    api_key != nil and api_key != ""
  end
  
  # Original API-based transformation (backwards compatibility)
  defp transform_with_api(description, context, server_id) do
    prompt = build_api_prompt(description, context, server_id)
    
    case request_anthropic_api(prompt) do
      {:ok, code_string} ->
        parse_ai_response(code_string)
      error ->
        error
    end
  end
  
  defp build_api_prompt(description, context, server_id) do
    context_str = if map_size(context) > 0 do
      "Current context:\n#{inspect(context, pretty: true, limit: 10)}\n\n"
    else
      ""
    end
    
    """
    #{context_str}Transform server #{server_id} to: #{description}
    
    Generate Elixir code that defines:
    1. A behavior function with signature: fn id, state, msg -> ... end
    2. Metadata describing the behavior
    
    The behavior function must return either:
    - {:continue, new_state}
    - {:become, new_behavior_fn, new_state}
    
    Format your response as valid Elixir code:
    
    behavior = fn id, state, msg ->
      # Implementation here
      {:continue, state}
    end
    
    metadata = %{
      type: :worker,  # or :cache, :database, :counter, etc
      capabilities: [:process],  # list of message types it handles
      description: "Brief description"
    }
    
    {behavior, metadata}
    
    Generate ONLY valid Elixir code, no explanations.
    """
  end
  
  defp request_anthropic_api(prompt) do
    api_key = System.get_env("ANTHROPIC_API_KEY")
    
    try do
      response = Req.post!(
        "https://api.anthropic.com/v1/messages",
        json: %{
          model: "claude-3-5-sonnet-20241022",
          max_tokens: 1024,
          messages: [%{role: "user", content: prompt}],
          system: "You are an expert Elixir developer generating code for Universal Servers. Generate only valid Elixir code with no markdown formatting or explanations."
        },
        headers: [
          {"x-api-key", api_key},
          {"anthropic-version", "2023-06-01"},
          {"content-type", "application/json"}
        ]
      )
      
      case response.body do
        %{"content" => [%{"text" => text} | _]} ->
          {:ok, text}
        _ ->
          {:error, "Unexpected response format"}
      end
    rescue
      e -> {:error, "AI request failed: #{inspect(e)}"}
    end
  end
  
  defp parse_ai_response(code_string) do
    # Try to compile and extract behavior and metadata
    case SafeCompiler.compile_with_result(code_string) do
      {:ok, {behavior, metadata}} when is_function(behavior, 3) and is_map(metadata) ->
        {:ok, behavior, metadata}
      {:ok, behavior} when is_function(behavior, 3) ->
        # If AI only returned a function, create default metadata
        {:ok, behavior, %{type: :transformed, capabilities: [], description: "AI-generated behavior"}}
      error ->
        error
    end
  end
end
