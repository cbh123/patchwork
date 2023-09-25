defmodule Patchwork.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset
  alias Patchwork.Games

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "games" do
    field :state, Ecto.Enum, values: [:start, :started, :finished], default: :start
    field :width, :integer
    field :height, :integer
    field :players, {:array, :string}, default: []
    field :current_patch_x, :integer, virtual: true
    field :current_patch_y, :integer, virtual: true
    field :logs, {:array, :string}, default: []
    field :loading_patches, {:array, :string}, default: [], virtual: true
    field :patches, :map, default: %{}

    timestamps()
  end

  @height 10
  @width 10

  defp init_patches() do
    for(i <- 0..(@height - 1), do: for(j <- 0..(@width - 1), do: {{i, j}, nil}))
    |> List.flatten()
    |> Enum.into(%{})
    |> tuples_to_string()
  end

  def new() do
    %{
      patches: init_patches(),
      height: @height,
      width: @width
    }
    |> Games.create_game!()
  end

  def new(height, width) do
    %{
      patches: init_patches(),
      height: height,
      width: width
    }
    |> Games.create_game!()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:state, :players, :logs, :height, :width, :patches, :loading_patches])
    |> validate_required([:height, :width])
  end

  def convert_to_internal_state(game) do
    game
    |> Map.put(:patches, string_to_tuples(game.patches))
    |> Map.put(:loading_patches, string_to_tuples(game.loading_patches))
  end

  def tuples_to_string(tuple_list) when is_list(tuple_list) do
    tuple_list
    |> Enum.map(fn {x, y} -> inspect({x, y}) end)
  end

  def tuples_to_string(map) when is_map(map) do
    map
    |> Enum.map(fn {{x, y}, value} -> {inspect({x, y}), value} end)
    |> Enum.into(%{})
  end

  def string_to_tuples(map) when is_map(map) do
    map
    |> Map.keys()
    |> Enum.map(fn string_tuple -> {parse_tuple(string_tuple), map[string_tuple]} end)
    |> Enum.into(%{})
  end

  def string_to_tuples(list) when is_list(list) do
    list
    |> Enum.map(&parse_tuple/1)
  end

  defp parse_tuple(input) when is_tuple(input), do: input

  defp parse_tuple(string) do
    string
    |> String.trim_trailing("}")
    |> String.trim_leading("{")
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple()
  end
end

# defmodule Patchwork.Games.Game do
#   @enforce_keys [:id, :patches, :height, :width]
#   defstruct id: nil,
#             patches: %{},
#             height: nil,
#             width: nil,
#             current_patch: nil,
#             # can be :start, :started, :finished
#             state: :start,
#             loading_patches: [],
#             players: [],
#             logs: []

#   defp init_patches() do
#     for(i <- 0..(@height - 1), do: for(j <- 0..(@width - 1), do: {{i, j}, nil}))
#     |> List.flatten()
#     |> Enum.into(%{})
#   end

#   def new() do
#     %Patchwork.Games.Game{
#       id: Ecto.UUID.generate(),
#       patches: init_patches(),
#       height: @height,
#       width: @width
#     }
#   end

#   def new(height, width) do
#     %Patchwork.Games.Game{
#       id: Ecto.UUID.generate(),
#       patches: init_patches(),
#       height: height,
#       width: width
#     }
#   end
# end
