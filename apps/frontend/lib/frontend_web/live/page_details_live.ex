defmodule FrontendWeb.PageDetailsLive do
  use FrontendWeb, :live_view
  # adjust if your API runs on a different port
  @api_url "http://localhost:4000/api/characters"

  def mount(%{"id" => id}, _session, socket) do
    # IO.inspect(params, label: "PageDetailsLive mount params")
    if connected?(socket), do: send(self(), {:load_character, id})
    {:ok, assign(socket, character: %{}, error: nil)}
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
    <h1>Character Details</h1>
    <%!-- <pre>
      <%= inspect(@character, pretty: true) %>
    </pre> --%>

    <%= if @error do %>
      <p style="color:red;">{@error}</p>
    <% else %>
      <%= if @character do %>
        <div>
          <h2>{@character["name"]}</h2>
          <img src={@character["image"]} />
        </div>
      <% else %>
        <p>Loading character details...</p>
      <% end %>
    <% end %>
    """
  end
end
