defmodule Patchwork.Games.Game do
  @enforce_keys [:id, :patches, :height, :width]
  defstruct id: nil,
            patches: %{},
            height: nil,
            width: nil,
            current_patch: nil,
            # can be :start, :started, :finished
            state: :start,
            loading_patches: [],
            players: [],
            logs: []

  @height 3
  @width 3

  defp init_patches() do
    for(i <- 0..(@height - 1), do: for(j <- 0..(@width - 1), do: {{i, j}, nil}))
    |> List.flatten()
    |> Enum.into(%{})
  end

  def new() do
    %Patchwork.Games.Game{
      id: Ecto.UUID.generate(),
      patches: init_patches(),
      height: @height,
      width: @width
    }
  end

  def new(height, width) do
    %Patchwork.Games.Game{
      id: Ecto.UUID.generate(),
      patches: init_patches(),
      height: height,
      width: width
    }
  end
end
