defmodule SafeCompiler do
  @moduledoc """
  Safe code compilation with basic sandboxing.
  """
  
  @forbidden_modules [
    :os,
    :file,
    File,
    System,
    Code,
    Node,
    :net_adm,
    :net_kernel,
    :init,
    :erlang,
    IO,
    Req,
    Universal,
    Capabilities
  ]
  
  @forbidden_functions [
    :spawn_link,
    :spawn_monitor,
    :spawn,
    :open_port,
    :exit,
    :halt,
    :throw
  ]
  
  def compile(code_string) do
    with {:ok, ast} <- Code.string_to_quoted(code_string),
         :ok <- verify_safety(ast),
         {result, _} <- Code.eval_quoted(ast, [], __ENV__) do
      {:ok, result}
    else
      {:error, reason} -> {:error, reason}
      error -> {:error, "Compilation failed: #{inspect(error)}"}
    end
  end
  
  def compile_with_result(code_string) do
    # Clean the code string of any markdown formatting
    cleaned_code = clean_code_string(code_string)
    
    with {:ok, ast} <- Code.string_to_quoted(cleaned_code),
         :ok <- verify_safety(ast),
         {result, _} <- Code.eval_quoted(ast, [], __ENV__) do
      {:ok, result}
    else
      {:error, reason} -> {:error, reason}
      error -> {:error, "Compilation failed: #{inspect(error)}"}
    end
  end
  
  defp clean_code_string(code) do
    code
    |> String.replace(~r/```elixir\n?/, "")
    |> String.replace(~r/```\n?/, "")
    |> String.trim()
  end
  
  defp verify_safety(ast) do
    case check_ast(ast) do
      :ok -> :ok
      {:error, _} = error -> error
    end
  end
  
  defp check_ast(ast) do
    Macro.prewalk(ast, :ok, fn
      node, :ok ->
        case check_node(node) do
          :ok -> {node, :ok}
          error -> {node, error}
        end
      node, acc ->
        {node, acc}
    end)
    |> elem(1)
  end
  
  defp check_node({:., _, [{:__aliases__, _, module_parts}, _func]}) do
    module = Module.concat(module_parts)
    if module in @forbidden_modules do
      {:error, "Forbidden module: #{module}"}
    else
      :ok
    end
  end
  
  defp check_node({{:., _, [module, _func]}, _, _}) when is_atom(module) do
    if module in @forbidden_modules do
      {:error, "Forbidden module: #{module}"}
    else
      :ok
    end
  end
  
  defp check_node({func, _, _}) when func in @forbidden_functions do
    {:error, "Forbidden function: #{func}"}
  end
  
  defp check_node({:import, _, _}) do
    {:error, "Import not allowed"}
  end
  
  defp check_node({:alias, _, _}) do
    # Allow alias for now, but could restrict
    :ok
  end
  
  defp check_node({:require, _, _}) do
    {:error, "Require not allowed"}
  end
  
  defp check_node({:use, _, _}) do
    {:error, "Use not allowed"}
  end
  
  defp check_node(_) do
    :ok
  end
end
