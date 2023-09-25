defmodule PatchworkWeb.HomeLive do
  use PatchworkWeb, :live_view
  alias Patchwork.Games

  def mount(_params, _session, socket) do
    {:ok, socket |> stream(:games, Games.list_games_where_top_left_is_not_nil())}
  end

  def render(assigns) do
    ~H"""
    <div class="p-12 mx-auto">
      <.header>Welcome to Patchwork</.header>
      <div class="mt-24">
        <.button phx-click="create">Create a Patchwork</.button>
      </div>

      <div class="mt-24">
        <.header>Join a Patchwork</.header>
        <ul
          role="list"
          class="mt-4 grid grid-cols-2 gap-x-4 gap-y-8 sm:grid-cols-3 sm:gap-x-6 lg:grid-cols-4 xl:gap-x-8"
        >
          <.link id={id} navigate={~p"/#{game.id}"} :for={{id, game} <- @streams.games} class="relative">
            <div class="group aspect-h-7 aspect-w-10 block w-full overflow-hidden rounded-lg bg-gray-100 focus-within:ring-2 focus-within:ring-indigo-500 focus-within:ring-offset-2 focus-within:ring-offset-gray-100">
              <img
                src={get_game_first_image(game)}
                alt=""
                class="object-cover group-hover:opacity-75"
              />
            </div>
          </.link>
          <!-- More files... -->
        </ul>
      </div>
    </div>
    """
  end

  defp get_game_first_image(game) do
    Games.get_patch!(game, {0, 0})
  end

  def handle_event("create", _, socket) do
    game = Games.new()
    {:noreply, socket |> push_navigate(to: ~p"/#{game.id}")}
  end
end
