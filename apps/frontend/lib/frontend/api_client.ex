defmodule Frontend.ApiClient do
  @api_url Application.compile_env(:frontend, :api_url, "http://localhost:4000/api/")
  def fetch_characters do
    case HTTPoison.get("#{@api_url}characters") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, data} -> {:ok, data}
          {:error, _} -> {:error, "Error decoding JSON"}
        end

      {:ok, %HTTPoison.Response{status_code: status}} ->
        {:error, "Unexpected status code: #{status}"}

      {:error, reason} ->
        {:error, "Error fetching characters: #{inspect(reason)}"}
    end
  end

  def search_options do
    case HTTPoison.get(@api_url <> "search_options") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Jason.decode(body)

      {:ok, %HTTPoison.Response{status_code: status}} ->
        {:error, "Unexpected status code: #{status}"}

      {:error, reason} ->
        {:error, "Error fetching characters: #{inspect(reason)}"}
    end
  end

  def fetch_character(id) do
    case HTTPoison.get(@api_url <> "/characters/" <> id) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, data} -> {:ok, data}
          {:error, _} -> {:error, "Error decoding JSON"}
        end

      {:ok, %HTTPoison.Response{status_code: status}} ->
        {:error, "Unexpected status code: #{status}"}

      {:error, reason} ->
        {:error, "Error fetching characters: #{inspect(reason)}"}
    end
  end

  def filter_characters(query, gender, species, status) do
    # TODO: user inputs or filter should be passed to api and filtered results should come from there
    case fetch_characters() do
      {:ok, data} ->
        filtered =
          data
          |> Enum.filter(fn char ->
            name_match =
              String.contains?(String.downcase(char["name"]), String.downcase(query || ""))

            gender_match = gender == "" || char["gender"] == gender
            species_match = species == "" || char["species"] == species
            status_match = status == "" || char["status"] == status
            name_match and gender_match and species_match and status_match
          end)

        filtered

      {:error, _error_message} ->
        []
    end
  end
end
