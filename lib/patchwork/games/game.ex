defmodule Patchwork.Games.Game do
  defstruct patches: %{},
            height: nil,
            width: nil,
            current_patch: nil,
            # can be :start, :started, :finished
            state: :start,
            loading_patches: []

  @height 10
  @width 10

  defp init_patches() do
    for(i <- 0..(@height - 1), do: for(j <- 0..(@width - 1), do: {{i, j}, nil}))
    |> List.flatten()
    |> Enum.into(%{})
  end

  def new() do
    %Patchwork.Games.Game{patches: init_patches(), height: @height, width: @width}
  end

  def new(height, width) do
    %Patchwork.Games.Game{patches: init_patches(), height: height, width: width}
  end
end
