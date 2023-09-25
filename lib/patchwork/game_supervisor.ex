defmodule Patchwork.GameSupervisor do
  use DynamicSupervisor

  @moduledoc """
  This profile supervisor allows us to create an arbitrary number of profile agents at runtime.
  """

  @me ProfileSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :no_args, name: @me)
  end

  def init(:no_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_game(game) do
    {:ok, pid} = DynamicSupervisor.start_child(@me, {Patchwork.Manager, game})
    {:ok, pid}
  end
end
