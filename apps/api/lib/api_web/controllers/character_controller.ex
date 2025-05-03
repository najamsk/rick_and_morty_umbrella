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

  # GET /api/characters/:id
  def show(conn, %{"id" => id}) do
    data = RickAndMortyApiClient.get_character(id)
    conn |> json(data)
  end
end
