defmodule ApiWeb.CharacterController do
  use ApiWeb, :controller

  alias Api.RickAndMortyApiClient

  # GET /api/characters
  def index(conn, _params) do
    conn
    |> json(RickAndMortyApiClient.all_characters())
  end

  # GET /api/search_options
  def search_options(conn, _params) do
    conn
    |> json(RickAndMortyApiClient.get_search_options())
  end

  # GET /api/characters?query=some_query&gender=some_gender&species=some_species&status=some_status
  def search(conn, %{
        "query" => query,
        "gender" => gender,
        "species" => species,
        "status" => status
      }) do
    data = RickAndMortyApiClient.filter_characters(query, gender, species, status)
    conn |> json(data)
  end

  # GET /api/characters/:id
  def show(conn, %{"id" => id}) do
    data = RickAndMortyApiClient.get_character(id)
    conn |> json(data)
  end
end
