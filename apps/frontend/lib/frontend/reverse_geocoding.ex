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

    case Req.get(url, follow_redirect: true) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        %{"address" => %{"city" => city, "country" => country}} = body
        {:ok, %{city: city, country: country}}

      {:ok, %Req.Response{status: status_code}} ->
        {:error, "HTTP request failed with status code #{status_code}"}

      {:error, reason} ->
        {:error, "HTTP request error: #{inspect(reason)}"}
    end
  end

  # def fetch_city_and_country(_, _) do
  #   {:error, "Invalid input. Latitude and longitude must be floats."}
  # end
end
