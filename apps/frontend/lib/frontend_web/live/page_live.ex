defmodule FrontendWeb.PageLive do
  use FrontendWeb, :live_view
  alias Frontend.ApiClient

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      send(self(), :load_all_initial_data)
    end

    socket =
      assign(socket, %{
        page_title: "Rick & Morty Characters!",
        characters: [],
        error: nil,
        query: "",
        gender: "",
        species: "",
        status: "",
        location: %{city: "", country: ""},
        search_options: %{"genders" => [], "species" => [], "statuses" => []}
      })

    {:ok, socket}
  end

  def handle_event("set_location", %{"latitude" => lat, "longitude" => lon}, socket) do
    Frontend.ReverseGeocoding.fetch_city_and_country(lat, lon)
    |> case do
      {:ok, %{city: city, country: country}} ->
        {:noreply, assign(socket, location: %{country: country, city: city})}

      {:error, reason} ->
        IO.puts("Error fetching location: #{reason}")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "search",
        %{"query" => query, "gender" => gender, "species" => species, "status" => status},
        socket
      ) do
    res =
      case ApiClient.filter_characters(query, gender, species, status) do
        {:ok, res} -> res
        {:error, _error_message} -> []
      end

    socket =
      assign(socket, %{
        characters: res,
        query: query,
        gender: gender,
        species: species,
        status: status
      })

    {:noreply, socket}
  end

  @impl true
  def handle_info(:load_all_initial_data, socket) do
    socket =
      case ApiClient.search_options() do
        {:ok, data} -> assign(socket, search_options: data)
        {:error, error_message} -> assign(socket, error: error_message)
      end

    socket =
      case ApiClient.fetch_characters() do
        {:ok, data} -> assign(socket, characters: data)
        {:error, error_message} -> assign(socket, error: error_message)
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @location.city != "" && @location.country != "" do %>
      <p class="text-center text-gray-500 mb-3">
        Hmm you portal from <strong>Earth: {@location.country} / {@location.city}</strong>
      </p>
    <% end %>
    <form
      id="geolocation-form"
      phx-change="search"
      class="space-y-4 mb-4 bg-gray-800 shadow-sm p-4 rounded-lg"
      phx-page-loading
      phx-hook="Geolocation"
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
              <img
                src={"/images/rick_and_morty_avatars/#{to_string(character["id"])}.jpeg"}
                alt=""
                class="w-full"
              />
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
