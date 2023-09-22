defmodule Patchwork.Games do
  alias Patchwork.Games.Game

  def new(), do: Game.new()

  def new(height, width), do: Game.new(height, width)

  def add_player(game, username) do
    if Enum.member?(game.players, username) do
      game
    else
      %{game | :players => game.players ++ [username]}
    end
  end

  def add_log(game, log) do
    %{game | :logs => game.logs ++ [log]} |> IO.inspect(label: "new game logs")
  end

  def set_patch!(game, {x, y}, url) do
    new_patches = %{game.patches | {x, y} => url}
    %{game | :patches => new_patches}
  end

  def select_patch(game, {x, y}) do
    %{game | :current_patch => {x, y}}
  end

  def update(game, key, value) do
    %{game | key => value}
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
    |> Enum.at(0)
    |> Patchwork.Images.crop_bottom_right()
    |> Patchwork.Images.save_r2!("game-#{game.id}-#{x}-#{y}")
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
end
