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
    with {:ok, data} <- fetch_characters() do
      query_downcased = String.downcase(query || "")

      Enum.filter(data, fn char ->
        String.contains?(String.downcase(char["name"]), query_downcased) and
          (gender == "" or char["gender"] == gender) and
          (species == "" or char["species"] == species) and
          (status == "" or char["status"] == status)
      end)
    else
      _ -> []
    end
  end
end
