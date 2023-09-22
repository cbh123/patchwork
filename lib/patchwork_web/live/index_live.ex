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
       me: nil,
       settings_form: to_form(%{"height" => game.height, "width" => game.width})
     )}
  end

  def handle_event("submit", %{"prompt" => prompt}, socket) do
    case GenServer.call(Manager, {:handle_prediction, prompt, socket.assigns.me}) do
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

  def handle_event("assign-username", %{"username" => username}, socket) do
    GenServer.call(Manager, {:add_player, username})
    {:noreply, socket |> assign(me: username)}
  end

  def handle_info({:update, game}, socket) do
    game.logs |> IO.inspect(label: "logs")
    socket = assign(socket, game: game)
    {:noreply, socket}
  end

  defp get(game, {row, col}) do
    Map.get(game.patches, {row, col})
  end
end
