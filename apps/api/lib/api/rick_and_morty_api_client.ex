defmodule Api.RickAndMortyApiClient do
  @moduledoc """
  A simple client to wrap Rick and Morty API calls.
  """

  alias Api.Data.Store

  @spec all_characters() :: any()
  def all_characters, do: Store.all_characters()

  @spec get_search_options() :: map()
  def get_search_options do
    %{
      genders: Store.all_genders(),
      species: Store.all_species(),
      statuses: Store.all_statuses()
    }
  end

  @spec get_character(integer()) :: any()
  def get_character(id), do: Store.get_character(id)
end
