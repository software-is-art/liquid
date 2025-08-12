defmodule Liquid.MixProject do
  use Mix.Project

  def project do
    [
      app: :liquid,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Absolute minimum - just HTTP client, use OTP's built-in :json module
      {:req, "~> 0.4"}      # HTTP client for AI APIs
    ]
  end
end
