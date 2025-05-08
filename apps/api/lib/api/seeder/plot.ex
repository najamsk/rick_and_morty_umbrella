defmodule Api.Seeder.Plot do
  require Logger

  @omdb_api_url "https://www.omdbapi.com/"
  @output_file_plot Path.join(:code.priv_dir(:api), "plots.json")
  @file_episode Path.join(:code.priv_dir(:api), "episodes.json")

  def load_episodes do
    case File.read(@file_episode) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, episodes} when is_list(episodes) ->
            Enum.map(episodes, fn episode ->
              %{
                # "air_date" => Map.get(episode, "air_date"),
                # "name" => Map.get(episode, "name"),
                "episode" => Map.get(episode, "episode")
              }
            end)

          {:error, reason} ->
            Logger.error("Failed to parse JSON: #{inspect(reason)}")
            []
        end

      {:error, reason} ->
        Logger.error("Failed to read file #{@file_episode}: #{inspect(reason)}")
        []
    end
  end

  def parse_season_and_episode(episode_string) do
    case Regex.run(~r/^S(\d{2})E(\d{2,3})$/, episode_string) do
      [_, season, episode] ->
        {:ok, %{season: String.to_integer(season), episode: String.to_integer(episode)}}

      _ ->
        {:error, "Invalid episode format: #{episode_string}"}
    end
  end

  def fetch_episode_details(season, episode) do
    api_key = System.get_env("OMDB_API_KEY") || ""

    url =
      "#{@omdb_api_url}?t=Rick+and+Morty&Season=#{season}&Episode=#{episode}&apikey=#{api_key}"

    # case Req.get(url, timeout: @http_timeout, receive_timeout: @http_timeout) do
    case Req.get(url) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        %{"Plot" => plot} = body
        plot

      {:ok, %Req.Response{status: status_code}} ->
        {:error, "HTTP request failed with status code #{status_code}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  def fetch_all_episode_details do
    episodes = load_episodes()

    if episodes == [] do
      Logger.error("No episodes loaded; aborting fetch.")
      {:error, :no_episodes}
    else
      result =
        episodes
        |> Task.async_stream(
          fn %{"episode" => episode_string} = episode ->
            case parse_season_and_episode(episode_string) do
              {:ok, %{season: season_num, episode: episode_num}} ->
                case fetch_episode_details(season_num, episode_num) do
                  plot when is_binary(plot) ->
                    key = "#{season_num}-#{episode_num}"
                    {key, Map.put(episode, "Plot", plot)}

                  {:error, reason} ->
                    Logger.error("Failed to fetch plot for #{episode_string}: #{reason}")
                    key = "#{season_num}-#{episode_num}"
                    {key, Map.put(episode, "Plot", "Unavailable")}
                end

              {:error, reason} ->
                Logger.error("Failed to parse episode string #{episode_string}: #{reason}")
                nil
            end
          end,
          max_concurrency: 5,
          # total per task
          timeout: 60_000
        )
        |> Enum.reduce(%{}, fn
          {:ok, {key, updated_episode}}, acc when not is_nil(key) ->
            Map.put(acc, key, updated_episode)

          _, acc ->
            acc
        end)

      case save_to_json_file(result, @output_file_plot) do
        :ok ->
          Logger.info("✅ Saved plots data to #{@output_file_plot}")
          {:ok, result}

        {:error, reason} ->
          Logger.error("Failed to save plots file: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  defp save_to_json_file(data, filename) do
    with {:ok, json} <- Jason.encode(data, pretty: true),
         :ok <- File.write(filename, json) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
