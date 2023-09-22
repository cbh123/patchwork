defmodule Patchwork.GameTest do
  use Patchwork.DataCase

  describe "game" do
    alias Patchwork.Games

    @game Games.new()

    test "basic gameplay" do
      assert @game.patches[{9, 9}] == nil
      assert @game.current_patch == nil

      # pick first patch
      curr = Games.pick_next_patch(@game)
      assert curr == {0, 0}

      # update game
      game = Games.select_patch(@game, curr)
      assert game.current_patch == {0, 0}

      # set patch
      url = Games.gen_test_image(@game, curr, "cat")
      game = Games.set_patch!(@game, curr, url)
      assert game.patches[curr] == url

      # pick next patch -- it'll be random
      curr = Games.pick_next_patch(game)
      assert curr in [{1, 0}, {0, 1}]

      # set patch
      game = Games.set_patch!(game, curr, url)

      # pick next patch
      curr = Games.pick_next_patch(game)
      assert curr in [{2, 0}, {1, 0}, {0, 1}, {1, 1}, {0, 2}]
    end

    test "won't pick patch to bottom or right of loading patch" do
      assert @game.state == :start
      curr = @game |> Games.pick_next_patch()

      assert curr == {0, 0}

      game =
        Games.set_patch!(@game, curr, "test")
        |> Games.update(:state, :started)
        |> Games.update(:loading_patches, [{0, 1}, {1, 0}])

      curr = Games.pick_next_patch(game)
      assert curr == nil
    end
  end
end
