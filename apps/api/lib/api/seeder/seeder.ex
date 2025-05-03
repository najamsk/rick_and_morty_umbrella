defmodule Api.Seeder.Seeder do
  @api_url_character "https://rickandmortyapi.com/api/character"
  @output_file_character Path.join(:code.priv_dir(:api), "characters.json")

  def fetch_and_save_characters do
    IO.puts("Fetching characters from Rick and Morty API...")
    characters = fetch_all_characters()
    save_to_file(characters, @output_file_character)
    # Publish the PubSub event
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

      {:error, reason} ->
        IO.inspect(reason, label: "HTTP Error")
        acc
    end
  end

  defp save_to_file(characters, file) do
    json = Jason.encode_to_iodata!(characters)
    File.write!(file, json)
    IO.puts("Saved #{length(characters)} characters to #{file}")
  end
end
