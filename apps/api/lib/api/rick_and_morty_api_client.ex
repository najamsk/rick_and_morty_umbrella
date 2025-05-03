defmodule Api.RickAndMortyApiClient do
  @moduledoc """
  A simple client to wrap the Rick and Morty API calls.
  """

  def all_characters do
    Api.Data.Store.all_characters()
  end

  def get_search_options do
    %{
      genders: Api.Data.Store.all_genders(),
      species: Api.Data.Store.all_species(),
      statuses: Api.Data.Store.all_statuses()
    }
  end

  def get_character(id) do
    Api.Data.Store.get_character(id)
  end
end
