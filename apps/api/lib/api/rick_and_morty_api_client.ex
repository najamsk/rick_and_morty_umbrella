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

  @spec filter_characters(String.t(), String.t(), String.t(), String.t()) :: list()
  def filter_characters(query, gender, species, status) do
    cahracters = Store.all_characters()
    query_downcased = String.downcase(query || "")

    Enum.filter(cahracters, fn char ->
      String.contains?(String.downcase(char["name"]), query_downcased) and
        (gender == "" or char["gender"] == gender) and
        (species == "" or char["species"] == species) and
        (status == "" or char["status"] == status)
    end)
  end

  @spec get_character(integer()) :: any()
  def get_character(id), do: Store.get_character(id)
end
