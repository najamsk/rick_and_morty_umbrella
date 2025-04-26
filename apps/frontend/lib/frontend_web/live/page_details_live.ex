defmodule FrontendWeb.PageDetailsLive do
  use FrontendWeb, :live_view
  # adjust if your API runs on a different port
  @api_url "http://localhost:4000/api/characters"

  def mount(%{"id" => id}, _session, socket) do
    # IO.inspect(params, label: "PageDetailsLive mount params")
    if connected?(socket), do: send(self(), {:load_character, id})
    {:ok, assign(socket, page_title: "Character Details", character: %{}, error: nil)}
  end

  def handle_info({:load_character, id}, socket) do
    case HTTPoison.get(@api_url <> "/" <> id) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        # Assume the API returns a JSON object that contains a "results" field
        data = Jason.decode!(body)
        IO.inspect(data, label: "PageDetailsLive handle_info data")
        # character = Map.get(data, "results", %{})
        {:noreply, assign(socket, character: data)}

      {:ok, %HTTPoison.Response{status_code: status}} ->
        {:noreply, assign(socket, error: "Unexpected status code: #{status}")}

      {:error, reason} ->
        {:noreply, assign(socket, error: "Error fetching characters: #{inspect(reason)}")}
    end
  end

  def render(assigns) do
    ~H"""
    <%!-- <pre>
      <%= inspect(@character, pretty: true) %>
    </pre> --%>

    <%= if @error do %>
      <p style="color:red;">{@error}</p>
    <% else %>
      <%= if @character do %>
        <div class="max-w-sm w-full lg:max-w-full lg:flex">
          <div
            class="h-48 lg:h-auto lg:w-48 flex-none bg-cover rounded-t lg:rounded-t-none lg:rounded-l text-center overflow-hidden"
            style={"background-image: url('#{@character["image"]}');"}
            title="Woman holding a mug"
          >
          </div>
          <div class="border-r border-b border-l border-gray-400 lg:border-l-0 lg:border-t lg:border-gray-400 bg-white rounded-b lg:rounded-b-none lg:rounded-r p-4 flex flex-col justify-between leading-normal">
            <div class="mb-8">
              <div class="text-gray-900 font-bold mb-3">
                <h2 class="text-xl font-bold ">
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
      <% else %>
        <p>Loading character details...</p>
      <% end %>
    <% end %>
    """
  end
end
