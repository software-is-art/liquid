defmodule AI.ClaudeCode do
  @moduledoc """
  Uses Claude Code CLI in print mode for transformations.
  Leverages existing Claude Max subscription without API keys.
  """
  
  def available? do
    case System.find_executable("claude") do
      nil -> false
      _path -> true
    end
  end
  
  def transform(description, context, server_id) do
    prompt = build_prompt(description, context, server_id)
    
    # Use claude in print mode - single shot, no conversation
    case execute_claude(prompt) do
      {:ok, output} ->
        output
        |> clean_output()
        |> SafeCompiler.compile_with_result()
        
      {:error, _} = error ->
        error
    end
  end
  
  defp execute_claude(prompt) do
    # Write to temp file to avoid shell escaping issues
    tmp_file = Path.join(System.tmp_dir!(), "liquid_prompt_#{:erlang.unique_integer()}.txt")
    File.write!(tmp_file, prompt)
    
    try do
      # Use claude -p for print mode (non-interactive)
      case System.cmd("claude", ["-p", prompt], 
                      stderr_to_stdout: true,
                      env: [{"CLAUDE_NO_ANALYTICS", "1"}]) do
        {output, 0} ->
          {:ok, output}
        {error_output, exit_code} ->
          {:error, "Claude Code failed (exit #{exit_code}): #{String.slice(error_output, 0, 200)}"}
      end
    after
      File.rm(tmp_file)
    end
  rescue
    e -> {:error, "Failed to execute claude: #{inspect(e)}"}
  end
  
  defp build_prompt(description, context, server_id) do
    context_info = if map_size(context) > 0 do
      "\nContext: #{inspect(context, pretty: true, limit: 5)}"
    else
      ""
    end
    
    """
    Generate ONLY valid Elixir code (no markdown formatting, no explanations) for a Universal Server behavior.
    
    The user wants to transform server #{server_id} to: "#{description}"#{context_info}
    
    Requirements:
    1. Define a behavior function with signature: fn id, state, msg -> ... end
    2. The function must return {:continue, new_state} or {:become, new_fn, new_state}
    3. Include metadata describing the behavior
    
    Generate EXACTLY this structure:
    
    behavior = fn id, state, msg ->
      case msg do
        # Pattern match based on "#{description}"
        _ -> {:continue, state}
      end
    end
    
    metadata = %{
      type: :worker,  # Choose appropriate: :counter, :cache, :accumulator, :worker, etc
      capabilities: [],  # List message patterns this behavior handles
      description: "#{description}"
    }
    
    {behavior, metadata}
    """
  end
  
  defp clean_output(output) do
    output
    |> String.trim()
    |> remove_markdown_formatting()
    |> extract_code_only()
  end
  
  defp remove_markdown_formatting(text) do
    text
    |> String.replace(~r/```elixir\s*\n/, "")
    |> String.replace(~r/```\s*\n/, "")
    |> String.replace(~r/\n```\s*/, "")
    |> String.replace(~r/```/, "")
  end
  
  defp extract_code_only(text) do
    # Remove any explanatory text before/after code
    case Regex.run(~r/behavior\s*=.*\{behavior,\s*metadata\}/s, text) do
      [code] -> code
      _ -> text  # Fallback to full text if pattern not found
    end
  end
end