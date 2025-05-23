defmodule FrontendWeb.PageDetailsLive do
  use FrontendWeb, :live_view
  require Logger
  alias Frontend.ApiClient

  # defp fetch_plot(season, episode) do
  #   # Construct the API URL with query parameters

  #   case ApiClient.fetch_plot(season, episode) do
  #     {:ok, %{"Plot" => plot}} ->
  #       {:ok, plot}

  #     {:ok, _} ->
  #       {:error, "Plot not found"}
  #   end
  # end

  defp extract_episode_ids(episodes) do
    episodes
    |> Enum.map(fn episode ->
      case Regex.run(~r/^S(\d{2})E(\d{2,3})$/, episode["episode"]) do
        [_, season, episode_num] ->
          "#{String.to_integer(season)}-#{String.to_integer(episode_num)}"

        _ ->
          nil
      end
    end)
    # Remove any nil values for invalid episode formats
    |> Enum.reject(&is_nil/1)
    # Join the extracted values with commas
    |> Enum.join(",")
  end

  @impl true
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
    case ApiClient.fetch_character(id) do
      {:ok, data} ->
        # Parse the season and episode from the "episode" string
        send(self(), {:load_character_episodes, data})

        {:noreply, assign(socket, character: data)}

      {:error, error_message} ->
        Logger.error("Error fetching character: #{error_message}")
        {:noreply, assign(socket, error: error_message)}
    end
  end

  @impl true
  def handle_info({:load_character_episodes, character}, socket) do
    # get comma-separated episode ids
    episode_ids = extract_episode_ids(character["episode"])

    # get plots for comma-separated episode ids
    {:ok, filtered_plots} = ApiClient.fetch_plots_by_ids(episode_ids)

    episodes =
      character["episode"]
      |> Task.async_stream(
        fn episode ->
          case Regex.named_captures(~r/S(?<season>\d+)E(?<episode>\d+)/, episode["episode"]) do
            %{"season" => season_number, "episode" => episode_number} ->
              season_number_trim =
                season_number
                |> String.to_integer()
                |> Integer.to_string()

              episode_number_trim =
                episode_number
                |> String.to_integer()
                |> Integer.to_string()

              plot_id = "#{season_number_trim}-#{episode_number_trim}"

              %{"Plot" => plot, "episode" => _} = Map.get(filtered_plots, "#{plot_id}")

              Map.put(episode, "plot", plot)

            # case fetch_plot(season_number, episode_number) do
            #   {:ok, plot} ->
            #     Map.put(episode, "plot", plot)

            #   {:error, error_message} ->
            #     Logger.warning(
            #       "Failed to fetch plot for S#{season_number}E#{episode_number}: #{error_message}"
            #     )

            #     episode
            # end

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

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @error do %>
      <p style="color:red;">{@error}</p>
    <% else %>
      <%= if @character != nil do %>
        <%= if @character == %{} do %>
          <p style="color:red;">Character Not found!</p>
        <% else %>
          <div class="w-full lg:max-w-3xl flex border-r border-b border-l border-t border-gray-400 lg:border-l-0  lg:border-gray-400 shadow-lg mx-auto mb-10">
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
