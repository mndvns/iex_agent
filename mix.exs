defmodule IExAgent.MixProject do
  use Mix.Project

  def project do
    [
      app: :iex_agent,
      version: "0.1.1",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: []
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end
end
