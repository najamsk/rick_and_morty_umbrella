defmodule Frontend.ReverseGeocoding do
  @moduledoc """
  A module to interact with the Nominatim OpenStreetMap Reverse Geocoding API.
  """

  @base_url "https://nominatim.openstreetmap.org/reverse"

  @doc """
  Fetches the city and country for the given latitude and longitude.

  ## Parameters
  - lat: Latitude as a float.
  - lon: Longitude as a float.

  ## Returns
  - {:ok, %{city: "City Name", country: "Country Name"}} on success.
  - {:error, reason} on failure.
  """
  def fetch_city_and_country(lat, lon) when is_float(lat) and is_float(lon) do
    url = "#{@base_url}?lat=#{lat}&lon=#{lon}&format=json"

    case HTTPoison.get(url, [], follow_redirect: true) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"address" => %{"city" => city, "country" => country}}} ->
            {:ok, %{city: city, country: country}}

          {:ok, %{"address" => %{"country" => country}}} ->
            {:ok, %{city: nil, country: country}}

          {:error, reason} ->
            {:error, "Failed to parse JSON: #{reason}"}

          _ ->
            {:error, "Unexpected response structure"}
        end

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, "HTTP request failed with status code #{status_code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTP request error: #{reason}"}
    end
  end

  # def fetch_city_and_country(_, _) do
  #   {:error, "Invalid input. Latitude and longitude must be floats."}
  # end
end
