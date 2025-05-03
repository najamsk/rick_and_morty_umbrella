defmodule Api.Data.Store do
  @moduledoc "Loads and caches character data from JSON file"

  @species_key :species_cache
  @genders_key :genders_cache
  @statuses_key :statuses_cache
  @characters_key :characters_map_cache
  @episodes_key :episodes_map_cache

  def load_data do
    # characters =
    #   Application.app_dir(:api, "priv/characters.json")
    #   |> File.read!()
    #   |> Jason.decode!()

    characters =
      with {:ok, content} <- File.read(Application.app_dir(:api, "priv/characters.json")),
           {:ok, data} <- Jason.decode(content) do
        data
      else
        _ -> []
      end

    episodes =
      with {:ok, content} <- File.read(Application.app_dir(:api, "priv/episodes.json")),
           {:ok, data} <- Jason.decode(content) do
        data
      else
        _ -> []
      end

    # dbg(characters)

    # :persistent_term.put(@key, characters)

    # Convert list to a map with id as key
    character_map = Map.new(characters, fn character -> {character["id"], character} end)
    episode_map = Map.new(episodes, fn episode -> {episode["id"], episode} end)
    :persistent_term.put(@characters_key, character_map)
    :persistent_term.put(@episodes_key, episode_map)

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
    IO.puts("Loaded #{length(characters)} characters")
    :ok
  end

  def all_characters do
    :persistent_term.get(@characters_key, %{})
    |> Map.values()
    |> Enum.shuffle()
  end

  def get_character(id) when is_binary(id), do: get_character(String.to_integer(id))

  def get_character(id) do
    IO.puts("Getting character with id: #{id}")

    case :persistent_term.get(@characters_key, %{}) |> Map.get(id) do
      nil ->
        %{}

      character ->
        episode_ids =
          character["episode"]
          |> Enum.map(&(String.split(&1, "/") |> List.last() |> String.to_integer()))

        updated_episodes = get_episodes_by_ids(episode_ids)

        character
        |> Map.put("episode", updated_episodes)
    end
  end

  defp get_episodes_by_ids(ids) do
    episodes = :persistent_term.get(@episodes_key, %{})

    result =
      ids
      |> Enum.reduce(%{}, fn id, acc ->
        case Map.fetch(episodes, id) do
          {:ok, episode} ->
            episode = Map.delete(episode, "characters")
            Map.put(acc, id, episode)

          :error ->
            acc
        end
      end)

    Map.values(result)
  end

  def all_species do
    :persistent_term.get(@species_key, %{})
  end

  def all_genders do
    :persistent_term.get(@genders_key, %{})
  end

  def all_statuses do
    :persistent_term.get(@statuses_key, %{})
  end
end
