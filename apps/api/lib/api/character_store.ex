defmodule Api.CharacterStore do
  @moduledoc "Loads and caches character data from JSON file"

  @key :characters_cache
  @species_key :species_cache
  @genders_key :genders_cache
  @statuses_key :statuses_cache
  @characters_key :characters_map_cache

  def load_data do
    IO.puts("Loading character data...")

    characters =
      Application.app_dir(:api, "priv/characters.json")
      |> File.read!()
      |> Jason.decode!()

    :persistent_term.put(@key, characters)

    # Convert list to a map with id as key
    character_map = Map.new(characters, fn character -> {character["id"], character} end)
    :persistent_term.put(@characters_key, character_map)

    species =
      characters
      |> Enum.map(& &1["species"])
      |> Enum.uniq()

    :persistent_term.put(@species_key, species)

    genders =
      characters
      |> Enum.map(& &1["gender"])
      |> Enum.uniq()

    :persistent_term.put(@genders_key, genders)

    statuses =
      characters
      |> Enum.map(& &1["status"])
      |> Enum.uniq()

    :persistent_term.put(@statuses_key, statuses)

    :ok
  end

  def all_characters_old do
    :persistent_term.get(@key)
  end

  def all_characters do
    :persistent_term.get(@characters_key)
    |> Map.values()
    |> Enum.shuffle()
  end

  def get_character(id) when is_binary(id), do: get_character(String.to_integer(id))

  def get_character(id) do
    :persistent_term.get(@characters_key)
    |> Map.get(id)
  end

  def all_species do
    :persistent_term.get(@species_key)
  end

  def all_genders do
    :persistent_term.get(@genders_key)
  end

  def all_statuses do
    :persistent_term.get(@statuses_key)
  end
end
