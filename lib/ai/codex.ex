defmodule AI.Codex do
  @moduledoc """
  Uses Codex CLI for transformations.

  Assumes `codex` is installed and available in PATH.
  """

  def available? do
    case System.find_executable("codex") do
      nil -> false
      _ -> true
    end
  end

  def transform(description, context, server_id) do
    prompt = build_prompt(description, context, server_id)

    with {:ok, output} <- execute_codex(prompt),
         {:ok, _} = compiled <- SafeCompiler.compile_with_result(clean_output(output)) do
      compiled
    else
      {:error, reason} ->
        repair_prompt = build_repair_prompt(description, context, server_id, reason)
        case execute_codex(repair_prompt) do
          {:ok, repaired} ->
            SafeCompiler.compile_with_result(clean_output(repaired))
          {:error, _} = e -> e
        end
    end
  end

  defp execute_codex(prompt) do
    # Simple non-interactive request; prefer passing prompt as arg
    try do
      case System.cmd("codex", ["-p", prompt], stderr_to_stdout: true) do
        {output, 0} -> {:ok, output}
        {error_output, exit_code} ->
          {:error, "Codex CLI failed (exit #{exit_code}): #{String.slice(error_output, 0, 200)}"}
      end
    rescue
      e -> {:error, "Failed to execute codex: #{inspect(e)}"}
    end
  end

  defp build_prompt(description, context, server_id) do
    context_info = if map_size(context) > 0 do
      "\nContext: #{inspect(context, pretty: true, limit: 5)}"
    else
      ""
    end

    """
    Generate ONLY valid Elixir code (no markdown, no explanations) for a Universal Server behavior.

    The user wants to transform server #{server_id} to: "#{description}"#{context_info}

    Requirements:
    1. Define a behavior function with signature: fn id, state, msg -> ... end
    2. The function must return {:continue, new_state} or {:become, new_fn, new_state}
    3. Include metadata describing the behavior

    Generate EXACTLY this structure:

    behavior = fn id, state, msg ->
      case msg do
        # Pattern match based on \"#{description}\"
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

  defp build_repair_prompt(description, context, server_id, reason) do
    base = build_prompt(description, context, server_id)
    """
    The previous attempt failed to compile with this error:
    #{inspect(reason)}

    Fix the code and regenerate ONLY the Elixir code in the exact required structure.
    #{base}
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
    case Regex.run(~r/behavior\s*=.*\{behavior,\s*metadata\}/s, text) do
      [code] -> code
      _ -> text
    end
  end
end
