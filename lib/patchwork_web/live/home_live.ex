defmodule PatchworkWeb.HomeLive do
  use PatchworkWeb, :live_view
  alias Patchwork.Games

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="mt-24 max-w-sm mx-auto">
    <.button phx-click="create">Create a Patchwork</.button>
    </div>
    """
  end

  def handle_event("create", _, socket) do
    game = Games.new()
    {:noreply, socket |> push_navigate(to: ~p"/#{game.id}")}
  end
end
