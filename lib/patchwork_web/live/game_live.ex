defmodule PatchworkWeb.GameLive do
  use PatchworkWeb, :live_view
  alias Patchwork.Games
  alias Patchwork.Manager

  def mount(%{"game_id" => game_id}, _session, socket) do
    if connected?(socket), do: Games.subscribe(game_id)

    game = Games.get_game!(game_id)

    unless Manager.whereis(game) do
      Patchwork.GameSupervisor.start_game(game)
    end

    {:ok,
     socket
     |> assign(
       game: game,
       me: nil,
       settings_form: to_form(%{"height" => game.height, "width" => game.width})
     )}
  end

  def handle_event("submit", %{"prompt" => prompt}, socket) do
    case Manager.handle_prediction(socket.assigns.game, prompt, socket.assigns.me) do
      :ok -> {:noreply, socket}
      str -> {:noreply, socket |> put_flash(:error, str)}
    end
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
    {:noreply, socket |> assign(game: game)}
  end

  defp get(game, {row, col}) do
    Map.get(game.patches, {row, col})
  end
end
