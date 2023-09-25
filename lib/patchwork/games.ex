defmodule Patchwork.Games do
  alias Patchwork.Games.Game
  import Ecto.Query, warn: false
  alias Patchwork.Repo

  def new(), do: Game.new()

  def new(height, width), do: Game.new(height, width)

  def add_player(game, username) do
    if Enum.member?(game.players, username) do
      game
    else
      update_game!(game, %{players: game.players ++ [username]})
    end
  end

  def add_log(game, log) do
    update_game!(game, %{logs: game.logs ++ [log]})
  end

  def get_patch!(game, {x, y}) do
    game
    |> Game.convert_to_internal_state()
    |> Map.get(:patches)
    |> Map.get({x, y})
  end

  def set_patch!(game, {x, y}, url) do
    new_patches = Map.put(game.patches, {x, y}, url)
    update_game!(game, %{patches: new_patches})
  end

  def select_patch(game, {x, y}) do
    update_game!(game, %{current_patch_x: x, current_patch_y: y})
  end

  def gen_image(_game, {0, 0}, prompt) do
    Replicate.run(
      "stability-ai/stable-diffusion:ac732df83cea7fff18b8472768c88ad041fa750ff7682a21affe81863cbe77e4",
      prompt: prompt,
      width: 768,
      height: 768
    )
    |> Enum.at(0)
  end

  def gen_image(game, {x, y}, prompt) do
    top_neighbor = Map.get(game.patches, {x - 1, y})
    left_neighbor = Map.get(game.patches, {x, y - 1})

    %{image: image, mask: mask, height: height, width: width} =
      Patchwork.Images.generate_image_and_mask(top_neighbor, left_neighbor)

    Replicate.run(
      "andreasjansson/stable-diffusion-inpainting:e490d072a34a94a11e9711ed5a6ba621c3fab884eda1665d9d3a282d65a21180",
      prompt: prompt,
      width: width,
      height: height,
      image: image,
      mask: mask
    )
    |> case do
      nil ->
        nil

      [image] ->
        image
        |> Patchwork.Images.crop_bottom_right()
        |> Patchwork.Images.save_r2!("game-#{game.id}-#{x}-#{y}")
    end
  end

  def gen_test_image(_game, {x, y}, _prompt) do
    if x < 2 or y < 2 do
      Process.sleep(100)
    else
      Process.sleep(10_000)
    end

    "https://robohash.org/1#{x}#{y}"
  end

  @doc """
  Picks next patch. Next patch is at the top left, or it hais
  top and left neighbors.
  """
  def pick_next_patch(game) do
    possible_coordinates =
      for i <- 0..(game.height - 1),
          j <- 0..(game.width - 1),
          valid_patch?(game, i, j),
          do: {i, j}

    case possible_coordinates do
      [] -> if game.state == :start, do: {0, 0}, else: nil
      _ -> Enum.random(possible_coordinates)
    end
  end

  def all_patches_full?(game) do
    game.patches
    |> Map.values()
    |> Enum.all?(&(&1 != nil))
  end

  def valid_patch?(game, x, y) do
    patch = Map.get(game.patches, {x, y})
    top_coords = {x - 1, y}
    left_coords = {x, y - 1}
    left_edge = x == 0
    top_edge = y == 0
    top_neighbor = Map.get(game.patches, top_coords)
    left_neighbor = Map.get(game.patches, left_coords)

    patch == nil and
      {x, y} not in game.loading_patches and
      top_coords not in game.loading_patches and
      left_coords not in game.loading_patches and
      if left_edge or top_edge do
        (top_neighbor != nil and !left_edge) or (left_neighbor != nil and !top_edge)
      else
        top_neighbor != nil and left_neighbor != nil
      end
  end

  alias Patchwork.Games.Game

  @doc """
  Returns the list of games.

  ## Examples

      iex> list_games()
      [%Game{}, ...]

  """
  def list_games do
    Repo.all(Game)
  end

  def list_games_where_top_left_is_not_nil do
    from(g in Game, where: not is_nil(g.patches["{0, 0}"])) |> Repo.all()
  end

  @doc """
  Gets a single game.

  Raises `Ecto.NoResultsError` if the Game does not exist.

  ## Examples

      iex> get_game!(123)
      %Game{}

      iex> get_game!(456)
      ** (Ecto.NoResultsError)

  """
  def get_game!(id), do: Repo.get!(Game, id) |> Game.convert_to_internal_state()

  @doc """
  Creates a game.

  ## Examples

      iex> create_game(%{field: value})
      {:ok, %Game{}}

      iex> create_game(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_game!(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert!()
    |> Game.convert_to_internal_state()
  end

  @doc """
  Updates a game.

  ## Examples

      iex> update_game(game, %{field: new_value})
      {:ok, %Game{}}

      iex> update_game(game, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_game!(%Game{} = game, attrs) do
    # if there are patches, convert them to string, because Ecto doesn't support tuples
    attrs =
      attrs
      |> Enum.map(fn {k, v} ->
        if k == :patches or k == :loading_patches do
          {k, Game.tuples_to_string(v)}
        else
          {k, v}
        end
      end)
      |> Enum.into(%{})

    game
    |> Game.changeset(attrs)
    |> Repo.update!()
    |> Game.convert_to_internal_state()
  end

  @doc """
  Deletes a game.

  ## Examples

      iex> delete_game(game)
      {:ok, %Game{}}

      iex> delete_game(game)
      {:error, %Ecto.Changeset{}}

  """
  def delete_game(%Game{} = game) do
    Repo.delete(game)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking game changes.

  ## Examples

      iex> change_game(game)
      %Ecto.Changeset{data: %Game{}}

  """
  def change_game(%Game{} = game, attrs \\ %{}) do
    Game.changeset(game, attrs)
  end

  # Live game logic
  def handle_prediction(game, prompt, user) do
    if all_patches_full?(game) do
      game = game |> update_game!(%{state: :finished}) |> broadcast()
      {:ok, game}
    else
      game
      |> pick_next_patch()
      |> handle_next_patch(prompt, user, game)
    end
  end

  def resize(game, height, width) do
    {:ok, _game} = delete_game(game)
    {:ok, new(height, width)}
  end

  def reset_game(game) do
    {:ok, _game} = delete_game(game)
    {:ok, new()}
  end

  defp handle_next_patch(nil, _prompt, _user, game) do
    {"No available squares — wait for some to load", game}
  end

  defp handle_next_patch({x, y}, prompt, user, game) do
    game =
      game
      |> update_game!(%{loading_patches: game.loading_patches ++ [{x, y}], state: :started})
      |> add_log("#{user} prompted '#{prompt}'")
      |> broadcast()

    image = gen_image(game, {x, y}, prompt)

    game =
      game
      |> update_game!(%{loading_patches: Enum.filter(game.loading_patches, &(&1 != {x, y}))})
      |> set_patch!({x, y}, image)
      |> broadcast()

    if image == nil do
      {"NSFW content detected — sorry! Try again...", game}
    else
      {:ok, game}
    end
  end

  defp broadcast(game) do
    Phoenix.PubSub.broadcast(Patchwork.PubSub, "play", {:update, game})
    game
  end

  def subscribe(), do: Phoenix.PubSub.subscribe(Patchwork.PubSub, "play")
end
