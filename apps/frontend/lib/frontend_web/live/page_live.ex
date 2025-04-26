defmodule FrontendWeb.PageLive do
  use FrontendWeb, :live_view
  alias Frontend.ApiClient

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      send(self(), :load_characters)
      send(self(), :load_search_options)
    end

    {:ok,
     assign(socket,
       page_title: "Rick & Morty Characters!",
       characters: [],
       error: nil,
       query: "",
       gender: "",
       species: "",
       status: "",
       search_options: %{"genders" => [], "species" => [], "statuses" => []}
     )}
  end

  @impl true
  def handle_event(
        "search",
        %{"query" => query, "gender" => gender, "species" => species, "status" => status},
        socket
      ) do
    res = ApiClient.filter_characters(query, gender, species, status)

    socket =
      socket
      |> assign(
        characters: res,
        query: query,
        gender: gender,
        species: species,
        status: status
      )

    {:noreply, socket}
  end

  @impl true
  def handle_info(:load_search_options, socket) do
    case ApiClient.search_options() do
      {:ok, data} -> {:noreply, assign(socket, search_options: data)}
      {:error, error_message} -> {:noreply, assign(socket, error: error_message)}
    end
  end

  def handle_info(:load_characters, socket) do
    case ApiClient.fetch_characters() do
      {:ok, data} -> {:noreply, assign(socket, characters: data)}
      {:error, error_message} -> {:noreply, assign(socket, error: error_message)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <form
      phx-change="search"
      class="space-y-4 mb-4 bg-gray-800 shadow-sm p-4 rounded-lg"
      phx-page-loading
    >
      <input
        type="text"
        name="query"
        value={@query}
        placeholder="Search by name..."
        class="w-full p-2 border rounded"
        phx-debounce="500"
      />
      <select name="gender" class="w-full p-2 border rounded">
        <option value="">All Genders</option>
        <%= for gender <- @search_options["genders"] do %>
          <option value={gender} selected={gender == @gender}>{gender}</option>
        <% end %>
      </select>
      <select name="species" class="w-full p-2 border rounded">
        <option value="">All Species</option>
        <%= for species <- @search_options["species"] do %>
          <option value={species} selected={species == @species}>{species}</option>
        <% end %>
      </select>
      <select name="status" class="w-full p-2 border rounded">
        <option value="">All Statuses</option>
        <%= for status <- @search_options["statuses"] do %>
          <option value={status} selected={status == @status}>{status}</option>
        <% end %>
      </select>
    </form>

    <%= if @error do %>
      <p style="color:red;">{@error}</p>
    <% else %>
      <ul class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
        <%= for character <- @characters do %>
          <li class="">
            <.link navigate={"/" <> to_string(character["id"])} class="relative">
              <img src={character["image"]} class="w-full" />
              <span class="absolute bottom-0 left-0 w-full  bg-gray-200/90 block text-center  ">
                {character["name"]}
              </span>
            </.link>
          </li>
        <% end %>
      </ul>
    <% end %>
    """
  end
end
