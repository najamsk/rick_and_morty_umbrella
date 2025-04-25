defmodule FrontendWeb.PageLive do
  use FrontendWeb, :live_view

  # adjust if your API runs on a different port
  @api_url "http://localhost:4000/api/characters"

  def mount(_params, _session, socket) do
    if connected?(socket), do: send(self(), :load_characters)
    {:ok, assign(socket, characters: [], error: nil, query: "", species_list: [])}
  end

  def handle_info(:load_characters, socket) do
    case HTTPoison.get(@api_url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        # Assume the API returns a JSON object that contains a "results" field
        data = Jason.decode!(body)
        # characters = data
        {:noreply, assign(socket, characters: data)}

      {:ok, %HTTPoison.Response{status_code: status}} ->
        {:noreply, assign(socket, error: "Unexpected status code: #{status}")}

      {:error, reason} ->
        {:noreply, assign(socket, error: "Error fetching characters: #{inspect(reason)}")}
    end
  end

  def render(assigns) do
    ~H"""
    <form phx-change="search" class="space-y-4 mb-4 bg-gray-800 shadow-sm p-4 rounded-lg">
      <input
        type="text"
        name="query"
        value={@query}
        placeholder="Search by name..."
        class="w-full p-2 border rounded"
      />

      <select name="gender" class="w-full p-2 border rounded">
        <option value="">All Genders</option>
        <option value="Male">Male</option>
        <option value="Female">Female</option>
        <option value="Genderless">Genderless</option>
        <option value="unknown">Unknown</option>
      </select>

      <select name="species" class="w-full p-2 border rounded">
        <option value="">All Species</option>
        <%= for species <- @species_list do %>
          <option value={species}>{species}</option>
        <% end %>
      </select>

      <select name="status" class="w-full p-2 border rounded">
        <option value="">All Statuses</option>
        <option value="Alive">Alive</option>
        <option value="Dead">Dead</option>
        <option value="unknown">Unknown</option>
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
