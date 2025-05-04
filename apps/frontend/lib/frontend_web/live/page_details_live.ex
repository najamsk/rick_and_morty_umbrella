defmodule FrontendWeb.PageDetailsLive do
  @api_url "https://www.omdbapi.com/"
  @api_key System.get_env("OMDB_API_KEY", "")
  use FrontendWeb, :live_view
  require Logger

  defp fetch_plot(season, episode) do
    # Construct the API URL with query parameters
    params = %{
      "t" => "Rick and Morty",
      "Season" => season,
      "Episode" => episode,
      "apikey" => @api_key
    }

    url = "#{@api_url}?#{URI.encode_query(params)}"
    # dbg(params)

    # Make the HTTP GET request
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        # Parse the JSON response
        case Jason.decode(body) do
          {:ok, %{"Plot" => plot}} ->
            {:ok, plot}

          {:ok, _} ->
            {:error, "Plot not found in response"}

          {:error, reason} ->
            {:error, "Failed to parse JSON: #{inspect(reason)}"}
        end

      {:ok, %HTTPoison.Response{status_code: status}} ->
        Logger.error("Unexpected status code: #{status}")
        {:error, "Unexpected status code: #{status}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("HTTP request failed: #{reason}")
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) and id not in [nil, ""] do
      send(self(), {:load_character, id})
    end

    {:ok,
     assign(socket, %{
       page_title: "Character Details",
       character: nil,
       error: nil
     })}
  end

  def handle_info({:load_character, id}, socket) do
    case Frontend.ApiClient.fetch_character(id) do
      {:ok, data} ->
        # Parse the season and episode from the "episode" string
        send(self(), {:load_character_episodes, data})

        {:noreply, assign(socket, character: data)}

      {:error, error_message} ->
        Logger.error("Error fetching character: #{error_message}")
        {:noreply, assign(socket, error: error_message)}
    end
  end

  def handle_info({:load_character_episodes, character}, socket) do
    episodes =
      character["episode"]
      |> Task.async_stream(
        fn episode ->
          case Regex.named_captures(~r/S(?<season>\d+)E(?<episode>\d+)/, episode["episode"]) do
            %{"season" => season_number, "episode" => episode_number} ->
              case fetch_plot(season_number, episode_number) do
                {:ok, plot} ->
                  Map.put(episode, "plot", plot)

                {:error, error_message} ->
                  Logger.warning(
                    "Failed to fetch plot for S#{season_number}E#{episode_number}: #{error_message}"
                  )

                  episode
              end

            nil ->
              Logger.error("Failed to parse season/episode from #{episode["episode"]}")
              episode
          end
        end,
        max_concurrency: 5,
        timeout: 10_000
      )
      |> Enum.map(fn
        {:ok, result} ->
          result

        {:exit, reason} ->
          Logger.error("Task failed with reason: #{inspect(reason)}")
          %{}
      end)

    # update data with episodes that have plot now
    updated_character = Map.put(character, "episode", episodes)
    {:noreply, assign(socket, character: updated_character)}
  end

  def render(assigns) do
    ~H"""
    <%= if @error do %>
      <p style="color:red;">{@error}</p>
    <% else %>
      <%= if @character != nil do %>
        <%= if @character == %{} do %>
          <p style="color:red;">Character Not found!</p>
        <% else %>
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
                <li class="card border-b border-gray-400 pb-4 mb-4 last:border-b-0">
                  <p class="text-gray-600 text-xl">
                    <strong>{episode["name"]}</strong>
                  </p>
                  <p class="info text-gray-500 mb-1">
                    <strong class="font-bold">{episode["episode"]}</strong> @{episode["air_date"]}
                  </p>
                  <%= if episode["plot"] do %>
                    <p class="text-gray-500 text-lg leading-6 text-black">
                      {episode["plot"]}
                    </p>
                  <% else %>
                    <p class="text-gray-500">
                      <strong>Plot:</strong> Loading...
                    </p>
                  <% end %>
                </li>
              <% end %>
            </ul>
          </div>
        <% end %>
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
