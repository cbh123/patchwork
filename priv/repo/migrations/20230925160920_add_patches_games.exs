defmodule Patchwork.Repo.Migrations.AddPatchesGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :patches, :map
    end
  end
end
