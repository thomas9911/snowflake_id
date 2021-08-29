defmodule SnowflakeId.MixProject do
  use Mix.Project

  def project do
    [
      app: :snowflake_id,
      version: "0.1.1",
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
      package: package(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.25", only: [:dev], runtime: false},
      {:benchee, "~> 1.0", only: [:dev]},
      {:excoveralls, "~> 0.10", only: :test},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false}
    ]
  end

  defp package do
    [
      licenses: [:unlicenced],
      links: %{
        github: "https://github.com/thomas9911/snowflake_id"
      }
    ]
  end

  defp aliases do
    [
      q: "do format, credo, dialyzer"
    ]
  end
end
