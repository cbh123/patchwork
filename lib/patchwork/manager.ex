defmodule Patchwork.Manager do
  use GenServer
  alias Patchwork.Games

  def start_link(game) do
    {:ok, pid} = GenServer.start_link(__MODULE__, game)
    {:ok, pid}
  end

  def init(game) do
    {:ok, game}
  end

  def handle_call({:handle_prediction, prompt, user}, _from, game) do
    if Games.all_patches_full?(game) do
      game = game |> Games.update_game!(%{state: :finished}) |> broadcast()
      {:reply, :ok, game}
    else
      game
      |> Games.pick_next_patch()
      |> handle_next_patch(prompt, user, game)
    end
  end

  def handle_call({:resize, height, width}, _from, _game) do
    game = Games.new(height, width) |> broadcast()
    {:reply, :ok, game}
  end

  def handle_call(:reset_game, _from, _game) do
    game = Games.new() |> broadcast()
    {:reply, :ok, game}
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
      |> broadcast()

    {:reply, :ok, game}
  end

  def handle_info({ref, {{row, col}, image}}, game) do
    Process.demonitor(ref, [:flush])

    game =
      %{game | loading_patches: Enum.filter(game.loading_patches, &(&1 != {row, col}))}
      |> Games.set_patch!({row, col}, image)
      |> broadcast()

    {:noreply, game}
  end

  defp gen_image({row, col}, prompt, game) do
    image = Games.gen_image(game, {row, col}, prompt)
    {{row, col}, image}
  end

  defp broadcast(game) do
    Phoenix.PubSub.broadcast(Patchwork.PubSub, "play", {:update, game})
    game
  end

  def subscribe(), do: Phoenix.PubSub.subscribe(Patchwork.PubSub, "play")
end
