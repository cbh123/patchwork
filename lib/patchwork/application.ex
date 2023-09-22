defmodule Patchwork.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      PatchworkWeb.Telemetry,
      # Start the Ecto repository
      Patchwork.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Patchwork.PubSub},
      # Start Finch
      {Finch, name: Patchwork.Finch},
      # Start the Endpoint (http/https)
      PatchworkWeb.Endpoint,
      {Patchwork.Manager, Patchwork.Games.Game.new()}
      # Start a worker by calling: Patchwork.Worker.start_link(arg)
      # {Patchwork.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Patchwork.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PatchworkWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
