defmodule FrontendWeb.PageDetailsLive do
  use FrontendWeb, :live_view

  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket), do: send(self(), {:load_character, id})
    {:ok, assign(socket, page_title: "Character Details", character: %{}, error: nil)}
  end

  def handle_info({:load_character, id}, socket) do
    case Frontend.ApiClient.fetch_character(id) do
      {:ok, data} ->
        {:noreply, assign(socket, character: data)}

      {:error, error_message} ->
        {:noreply, assign(socket, error: error_message)}
    end
  end

  def render(assigns) do
    ~H"""
    <%= if @error do %>
      <p style="color:red;">{@error}</p>
    <% else %>
      <%= if @character != %{} do %>
        <div class="w-full lg:max-w-3xl flex border-r border-b border-l border-gray-400  lg:border-l-0 lg:border-t lg:border-gray-400 shadow-lg mx-auto mb-10">
          <div
            class="h-100 w-48 lg:h-auto lg:w-48 bg-cover rounded-t lg:rounded-t-none lg:rounded-l text-center overflow-hidden"
            style={"background-image: url('/images/rick_and_morty_avatars/#{to_string(@character["id"])}.jpeg');"}
            title="Woman holding a mug"
          >
          </div>
          <div class=" bg-white rounded-b lg:rounded-b-none lg:rounded-r p-4 flex flex-col justify-between leading-normal">
            <div class="mb-8">
              <div class="text-gray-900 font-bold mb-3">
                <h2 class="text-xl font-bold text-indigo-600">
                  {@character["name"]}
                </h2>
                <p>
                  <span class={"status " <> (if @character["status"] == "Alive", do: "status-alive", else: "status-dead")}>
                  </span> {@character["status"]} - {@character["species"]}
                </p>
              </div>
              <p><strong>Last Location:</strong> {@character["location"]["name"]}</p>
              <p><strong>Status:</strong> {@character["status"]}</p>
              <p><strong>Specie:</strong> {@character["species"]}</p>
              <p><strong>Gender:</strong> {@character["gender"]}</p>
            </div>
          </div>
        </div>
        <%!-- card --%>
        <%!-- episode list start --%>
        <div class="details w-full lg:max-w-3xl mx-auto">
          <h2 class="text-3xl font-bold mb-3 text-indigo-600">Episodes</h2>
          <ul>
            <%= for episode <- @character["episode"] do %>
              <li class="card border-b border-gray-400 pb-2 mb-4 last:border-b-0">
                <p class="text-gray-600 text-xl">
                  <strong>{episode["name"]}</strong>
                </p>
                <p class="info text-gray-500">
                  <strong class="font-bold"> {episode["episode"]}</strong>, {episode["air_date"]}
                </p>
              </li>
            <% end %>
          </ul>
        </div>
        <%!-- episode list end --%>
      <% else %>
        <p>Loading character details...</p>
      <% end %>
    <% end %>
    <%!-- <pre>
      <%= inspect(@character, pretty: true) %>
    </pre> --%>
    """
  end
end
