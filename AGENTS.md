# Repository Guidelines

## Project Structure & Module Organization
- `lib/`: Core source code (e.g., `Universal`, `Liquid`, `Context`, `Observer`, `SafeCompiler`).
- `lib/ai/`: AI backends (`AI.Mock`, `AI.Ollama`, `AI.ClaudeCode`).
- `test/`: ExUnit tests (files end with `_test.exs`).
- `_build/`, `deps/`: Build artifacts and dependencies (generated).
- `devbox.json`, `.devbox/`: Optional Devbox environment for local tooling.

## Build, Test, and Development Commands
- `devbox shell`: Enter the provided dev environment (optional).
- `mix deps.get`: Install dependencies.
- `mix compile`: Compile the project.
- `mix format`: Auto-format using `.formatter.exs`.
- `mix test` / `mix test --cover`: Run tests with optional coverage.
- `iex -S mix` → `Liquid.start()`: Start the interactive system and REPL.

## Coding Style & Naming Conventions
- Language: Elixir `~> 1.18`. Use `mix format` before pushing.
- Indentation: 2 spaces; keep lines readable (<100 chars when practical).
- Files: snake_case (e.g., `universal.ex`, `liquid_registry.ex`).
- Modules: PascalCase; follow existing patterns (top-level like `Universal`, namespaced like `LiquidRegistry`, `AI.*`).
- Docs: Add `@moduledoc`/`@doc` for public modules/functions; prefer clear examples.

## Testing Guidelines
- Framework: ExUnit. Place tests in `test/` with names like `foo_test.exs`.
- Structure: One focused behavior per test; prefer message-passing assertions over sleeps (use small `Process.sleep/1` only when necessary).
- Run: `mix test` locally; keep tests deterministic and backend-agnostic (use `AI.Mock`).

## Commit & Pull Request Guidelines
- Commits: Imperative mood and scoped when helpful (e.g., `ai: improve ollama timeouts`).
- PRs: Describe motivation, changes, and how to verify (include sample `iex` session if relevant). Link issues. Keep diffs small and focused. Update docs when behavior changes.

## Security & Configuration Tips
- Backends: `AI` auto-detects backends. Use `AI.set_backend/1` or in REPL `Liquid.start()` then `> use mock|ollama|claude_code`.
- Config: `ANTHROPIC_API_KEY` for API; `LIQUID_OLLAMA_MODEL` to select Ollama model; Ollama listens on `http://localhost:11434`.
- Safety: `SafeCompiler` blocks dangerous calls, but treat generated code as untrusted. Never commit secrets.

