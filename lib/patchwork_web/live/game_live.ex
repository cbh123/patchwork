defmodule PatchworkWeb.GameLive do
  use PatchworkWeb, :live_view
  alias Patchwork.Games

  def mount(%{"game_id" => game_id}, _session, socket) do
    if connected?(socket), do: Games.subscribe()

    game = Games.get_game!(game_id)

    {:ok,
     socket
     |> assign(
       game: game,
       me: nil,
       settings_form: to_form(%{"height" => game.height, "width" => game.width})
     )}
  end

  def handle_event("submit", %{"prompt" => prompt}, socket) do
    Task.async(fn -> Games.handle_prediction(socket.assigns.game, prompt, socket.assigns.me) end)

    {:noreply, socket}
  end

  def handle_event("submit-settings", %{"height" => height, "width" => width}, socket) do
    {:ok, new_game} =
      Games.resize(
        socket.assigns.game,
        height |> String.to_integer(),
        width |> String.to_integer()
      )

    {:noreply, socket |> redirect(to: ~p"/#{new_game.id}")}
  end

  def handle_event("reset", _value, socket) do
    {:ok, new_game} = Games.reset_game(socket.assigns.game)
    {:noreply, socket |> redirect(to: ~p"/#{new_game.id}")}
  end

  def handle_event("assign-username", %{"username" => username}, socket) do
    Games.add_player(socket.assigns.game, username)
    {:noreply, socket |> assign(me: username)}
  end

  def handle_info({:update, game}, socket) do
    socket = assign(socket, game: game)
    {:noreply, socket}
  end

  def handle_info({ref, {:ok, game}}, socket) do
    Process.demonitor(ref, [:flush])

    {:noreply, socket}
  end

  def handle_info({ref, {msg, game}}, socket) do
    Process.demonitor(ref, [:flush])

    {:noreply, socket |> put_flash(:error, msg)}
  end

  defp get(game, {row, col}) do
    Map.get(game.patches, {row, col})
  end
end
