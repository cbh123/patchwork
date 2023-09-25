defmodule Patchwork.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :state, :string
      add :players, {:array, :string}
      add :current_patch, {:array, :integer}
      add :logs, {:array, :string}
      add :height, :integer
      add :width, :integer

      timestamps()
    end
  end
end
