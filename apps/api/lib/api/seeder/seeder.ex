defmodule Api.Seeder.Seeder do
  @moduledoc """
  This module fetches data from the Rick and Morty API and saves it to JSON files.
  It uses HTTPoison for HTTP requests and Jason for JSON encoding/decoding.
  """
  @api_url_character "https://rickandmortyapi.com/api/character"
  @api_url_episode "https://rickandmortyapi.com/api/episode"
  @output_file_character Path.join(:code.priv_dir(:api), "characters.json")
  @output_file_episode Path.join(:code.priv_dir(:api), "episodes.json")
  # @default_timeout Application.get_env(:api, :http_timeout, 10_000)

  def fetch_and_save_characters do
    IO.puts("Fetching characters from Rick and Morty API...")
    characters = fetch_all_characters()
    save_to_file(characters, @output_file_character)
    # Publish the PubSub event
  end

  def fetch_and_save_episodes do
    IO.puts("Fetching episodes from Rick and Morty API...")
    episodes = fetch_all_episodes()
    save_to_file(episodes, @output_file_episode)
  end

  defp fetch_all_characters do
    fetch_all_character_pages(@api_url_character, [])
  end

  defp fetch_all_character_pages(nil, acc), do: acc

  defp fetch_all_character_pages(url, acc) do
    case HTTPoison.get(url, [], recv_timeout: 10_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        %{"info" => %{"next" => next_url}, "results" => results} = Jason.decode!(body)
        fetch_all_character_pages(next_url, acc ++ results)

      {:ok, %HTTPoison.Response{status_code: code}} ->
        IO.puts("Failed with HTTP code: #{code}")
        acc

      {:error, _reason} ->
        # IO.inspect(reason, label: "HTTP Error")
        acc
    end
  end

  defp fetch_all_episodes do
    fetch_all_episode_pages(@api_url_episode, [])
  end

  defp fetch_all_episode_pages("", acc), do: Enum.reverse(acc)
  defp fetch_all_episode_pages(nil, acc), do: Enum.reverse(acc)

  defp fetch_all_episode_pages(url, acc) do
    case HTTPoison.get(url, [], recv_timeout: 10_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        %{"info" => %{"next" => next_url}, "results" => results} = Jason.decode!(body)
        fetch_all_episode_pages(next_url, results ++ acc)

      {:ok, %HTTPoison.Response{status_code: code}} ->
        IO.puts("Failed with HTTP code: #{code}")
        acc

      {:error, _reason} ->
        acc
    end
  end

  defp save_to_file(characters, file) do
    json = Jason.encode_to_iodata!(characters)
    File.write!(file, json)
    IO.puts("Saved #{length(characters)} characters to #{file}")
  end
end
