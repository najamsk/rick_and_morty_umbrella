defmodule Frontend.ApiClient do
  @moduledoc """
  A client for fetching character data from the Rick and Morty API.
  """
  @api_url Application.compile_env(:frontend, :api_url, "http://localhost:4000/api/")
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
