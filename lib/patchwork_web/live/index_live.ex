defmodule PatchworkWeb.IndexLive do
  use PatchworkWeb, :live_view
  alias Patchwork.Manager
  alias Phoenix.LiveView.JS

  def mount(_params, _session, socket) do
    if connected?(socket), do: Manager.subscribe()
    game = GenServer.call(Manager, :get_game)

    {:ok,
     socket
     |> assign(
       game: game,
       prediction: nil,
       settings_form: to_form(%{"height" => game.height, "width" => game.width})
     )}
  end

  def handle_event("submit", %{"prompt" => prompt}, socket) do
    case GenServer.call(Manager, {:handle_prediction, prompt}) do
      :ok -> {:noreply, socket}
      str -> {:noreply, socket |> put_flash(:error, str)}
    end
  end

  def handle_event("submit-settings", %{"height" => height, "width" => width}, socket) do
    GenServer.call(
      Manager,
      {:resize, height |> String.to_integer(), width |> String.to_integer()}
    )

    {:noreply, socket}
  end

  def handle_event("reset", _value, socket) do
    GenServer.call(Manager, :reset_game)
    {:noreply, socket}
  end

  def handle_info({:update, game}, socket) do
    socket = assign(socket, game: game, loading: false)
    {:noreply, socket}
  end

  defp get(game, {row, col}) do
    Map.get(game.patches, {row, col})
  end
end
