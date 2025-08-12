defmodule AI.Ollama do
  @moduledoc """
  Uses local Ollama instance for transformations.
  Free, local, and private.
  """
  
  @ollama_url "http://localhost:11434"
  @default_model "codellama"  # or mistral, llama2, etc.
  
  def available? do
    case check_ollama_server() do
      {:ok, _} -> true
      _ -> false
    end
  end
  
  def transform(description, context, server_id) do
    prompt = build_prompt(description, context, server_id)
    
    case generate_completion(prompt) do
      {:ok, response} ->
        response
        |> clean_output()
        |> SafeCompiler.compile_with_result()
        
      {:error, _} = error ->
        error
    end
  end
  
  defp check_ollama_server do
    try do
      response = Req.get!("#{@ollama_url}/api/tags", retry: false, connect_timeout: 1000)
      if response.status == 200 do
        {:ok, response.body}
      else
        {:error, :not_available}
      end
    rescue
      _ -> {:error, :not_running}
    end
  end
  
  defp generate_completion(prompt) do
    model = System.get_env("LIQUID_OLLAMA_MODEL", @default_model)
    
    try do
      response = Req.post!(
        "#{@ollama_url}/api/generate",
        json: %{
          model: model,
          prompt: prompt,
          stream: false,
          options: %{
            temperature: 0.7,
            top_p: 0.9
          }
        },
        receive_timeout: 30_000,
        retry: false
      )
      
      case response.body do
        %{"response" => generated_text} ->
          {:ok, generated_text}
        _ ->
          {:error, "Unexpected Ollama response format"}
      end
    rescue
      e -> {:error, "Ollama generation failed: #{inspect(e)}"}
    end
  end
  
  defp build_prompt(description, context, server_id) do
    context_info = if map_size(context) > 0 do
      "\nCurrent system context: #{inspect(context, pretty: true, limit: 5)}"
    else
      ""
    end
    
    """
    You are generating Elixir code for a Universal Server that can transform its behavior.
    
    Task: Transform server #{server_id} to: "#{description}"#{context_info}
    
    Generate ONLY valid Elixir code with this exact structure:
    
    behavior = fn id, state, msg ->
      # Implementation for: #{description}
      # Must pattern match on messages and update state
      case msg do
        # Add patterns based on the description
        _ -> {:continue, state}
      end
    end
    
    metadata = %{
      type: :worker,  # or :counter, :cache, :echo, etc based on description
      capabilities: [],  # list of message atoms this handles
      description: "#{description}"
    }
    
    {behavior, metadata}
    
    Output only the Elixir code, no explanations.
    """
  end
  
  defp clean_output(output) do
    output
    |> String.trim()
    |> remove_markdown_formatting()
  end
  
  defp remove_markdown_formatting(text) do
    text
    |> String.replace(~r/```elixir\s*\n/, "")
    |> String.replace(~r/```\s*\n/, "")
    |> String.replace(~r/\n```\s*/, "")
    |> String.replace(~r/```/, "")
  end
end