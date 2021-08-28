defmodule SnowflakeId.MixProject do
  use Mix.Project

  def project do
    [
      app: :snowflake_id,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      description: "Snowflake Identifier in Elixir, based on Rust's rs-snowflake",
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      package: [
        licenses: [:unlicenced],
        links: %{
          github: "https://github.com/thomas9911/snowflake_id"
        }
      ],
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
      {:ex_doc, ">= 0.0.0", only: [:dev], runtime: false},
      {:benchee, ">= 0.0.0", only: [:dev]},
      {:excoveralls, "~> 0.10", only: :test},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end
end
