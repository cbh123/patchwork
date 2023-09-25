defmodule Patchwork.Manager do
  use GenServer
  alias Patchwork.Games

  def start_link(game) do
    GenServer.start_link(__MODULE__, game, name: via_tuple(game.id))
  end

  defp via_tuple(game_id) do
    {:via, Registry, {Patchwork.GameRegistry, game_id}}
  end

  def whereis(game) do
    GenServer.whereis(via_tuple(game.id))
  end

  def init(game) do
    {:ok, game}
  end

  def handle_prediction(game, prompt, user) do
    GenServer.call(via_tuple(game.id), {:handle_prediction, prompt, user})
  end

  def handle_call({:handle_prediction, prompt, user}, _from, game) do
    if Games.all_patches_full?(game) do
      game = Games.update_game!(game, %{state: :finished})
      {:reply, :ok, game}
    else
      game
      |> Games.pick_next_patch()
      |> handle_next_patch(prompt, user, game)
    end
  end

  defp handle_next_patch(nil, _prompt, _user, game) do
    {:reply, "No available squares — wait for some to load", game}
  end

  defp handle_next_patch({x, y}, prompt, user, game) do
    Task.async(fn -> gen_image({x, y}, prompt, game) end)

    game =
      game
      |> Games.select_patch({x, y})
      |> Games.update_game!(%{loading_patches: game.loading_patches ++ [{x, y}], state: :started})
      |> Games.add_log("#{user} prompted '#{prompt}'")

    {:reply, :ok, game}
  end

  def handle_info({ref, {{row, col}, nil}}, game) do
    Process.demonitor(ref, [:flush])

    {:noreply, game}
  end

  def handle_info({ref, {{row, col}, image}}, game) do
    Process.demonitor(ref, [:flush])

    game =
      game
      |> Games.update_game!(%{
        loading_patches: Enum.filter(game.loading_patches, &(&1 != {row, col}))
      })
      |> Games.set_patch!({row, col}, image)

    {:noreply, game}
  end

  defp gen_image({row, col}, prompt, game) do
    image = Games.gen_image(game, {row, col}, prompt)
    {{row, col}, image}
  end
end
