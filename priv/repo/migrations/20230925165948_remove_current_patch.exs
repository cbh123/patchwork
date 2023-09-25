defmodule Patchwork.Repo.Migrations.DropCurrentPatch do
  use Ecto.Migration

  def change do
    alter table(:games) do
      remove :current_patch
    end
  end
end
