defmodule Frontend.ApiClient do
  @moduledoc """
  A client for fetching character data from the Rick and Morty API.
  """
  @api_url Application.compile_env(:frontend, :api_url, "http://localhost:4000/api/")
  @api_key System.get_env("OMDB_API_KEY", "")
  require Logger
  alias Frontend.PlotStore.Store
  defp build_url(path), do: "#{@api_url}#{path}"

  # Private helper to handle HTTP response and JSON decoding
  defp handle_api_response(response, error_message) do
    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, data} when data != [] -> {:ok, data}
          {:ok, []} -> {:error, "No data"}
          {:error, _} -> {:error, "Error decoding JSON"}
        end

      {:ok, %HTTPoison.Response{status_code: status}} ->
        {:error, "Unexpected status code: #{status}"}

      {:error, reason} ->
        {:error, "#{error_message}: #{inspect(reason)}"}
    end
  end

  def fetch_characters do
    "characters"
    |> build_url()
    |> HTTPoison.get()
    |> handle_api_response("Error fetching characters")
  end

  def search_options do
    "search_options"
    |> build_url()
    |> HTTPoison.get()
    |> handle_api_response("Error fetching search options")
  end

  def fetch_character(id) do
    "characters/#{id}"
    |> build_url()
    |> HTTPoison.get()
    |> handle_api_response("Error fetching character")
  end

  def fetch_plots_by_ids(ids) do
    "plots/#{ids}"
    |> build_url()
    |> HTTPoison.get()
    |> handle_api_response("Error fetching plots")
  end

  def fetch_plot(season, episode) do
    # Get plot from GenServer
    case Store.get_plot("#{season}_#{episode}") do
      {:ok, plot} ->
        Logger.info("Plot found in GenServer for season #{season}, episode #{episode}")
        {:ok, %{"Plot" => plot}}

      {:error, reason} ->
        Logger.info(
          "Plot not found in GenServer for season #{season}, episode #{episode}: #{inspect(reason)}"
        )

        if @api_key == "" do
          Logger.error(
            "OMDB API key is missing. Please set the OMDB_API_KEY environment variable."
          )

          {:error, :missing_api_key}
        else
          params = %{
            "t" => "Rick and Morty",
            "Season" => season,
            "Episode" => episode,
            "apikey" => @api_key
          }

          api_plot_url = "https://www.omdbapi.com/?#{URI.encode_query(params)}"

          Logger.info(
            "Fetching plot from OMDB API for season #{season}, episode #{episode}: #{api_plot_url}"
          )

          res =
            api_plot_url
            |> HTTPoison.get([], timeout: 5_000, recv_timeout: 10_000)
            |> handle_api_response("Error fetching plot")

          case res do
            {:ok, %{"Plot" => plot}} ->
              case Store.add_plot("#{season}_#{episode}", plot) do
                :ok ->
                  Logger.info("Plot cached successfully for season #{season}, episode #{episode}")

                {:error, reason} ->
                  Logger.error(
                    "Failed to cache plot for season #{season}, episode #{episode}: #{inspect(reason)}"
                  )
              end

              {:ok, %{"Plot" => plot}}

            {:error, reason} ->
              Logger.error("Failed to fetch plot from OMDB API: #{inspect(reason)}")
              {:error, reason}

            _ ->
              Logger.error("Unexpected response from OMDB API: #{inspect(res)}")
              {:error, :unexpected_response}
          end
        end
    end
  end

  def filter_characters(query \\ "", gender \\ "", species \\ "", status \\ "") do
    params =
      URI.encode_query(%{
        query: query,
        gender: gender,
        species: species,
        status: status
      })

    build_url("characters/search?#{params}")
    |> HTTPoison.get()
    |> handle_api_response("Error filtering characters")
  end
end
