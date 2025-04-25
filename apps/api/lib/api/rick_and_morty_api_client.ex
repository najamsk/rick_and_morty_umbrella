defmodule Api.RickAndMortyApiClient do
  @moduledoc """
  A simple client to wrap the Rick and Morty API calls.
  """

  def all_characters do
    Api.CharacterStore.all_characters()
  end

  def get_search_options do
    %{
      genders: Api.CharacterStore.all_genders(),
      species: Api.CharacterStore.all_species(),
      statuses: Api.CharacterStore.all_statuses()
    }
  end

  def get_character(id) do
    Api.CharacterStore.get_character(id)
  end
end
