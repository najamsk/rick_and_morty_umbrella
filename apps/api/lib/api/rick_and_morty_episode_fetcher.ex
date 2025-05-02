defmodule Api.RickAndMortyEpisodeFetcher do
  @api_url "https://rickandmortyapi.com/api/episode"
  @output_file Path.join(:code.priv_dir(:api), "episodes.json")
  @default_timeout Application.get_env(:api, :http_timeout, 10_000)

  def fetch_and_save_episodes do
    IO.puts("Fetching episodes from Rick and Morty API...")
    episodes = fetch_all_episodes()
    save_to_file(episodes, @output_file)

    # Publish the PubSub event
    # Phoenix.PubSub.broadcast(Api.PubSub, "locations", {:locations_fetched, locations})
  end

  defp fetch_all_episodes do
    fetch_all_pages(@api_url, [])
  end

  defp fetch_all_pages("", acc), do: Enum.reverse(acc)
  defp fetch_all_pages(nil, acc), do: Enum.reverse(acc)

  defp fetch_all_pages(url, acc) do
    case HTTPoison.get(url, [], recv_timeout: @default_timeout) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        %{"info" => %{"next" => next_url}, "results" => results} = Jason.decode!(body)
        fetch_all_pages(next_url, results ++ acc)

      {:ok, %HTTPoison.Response{status_code: code}} ->
        IO.puts("Failed with HTTP code: #{code}")
        acc

      {:error, reason} ->
        IO.inspect(reason, label: "HTTP Error")
        acc
    end
  end

  defp save_to_file(data, file) do
    json = Jason.encode_to_iodata!(data)

    case File.write(file, json) do
      :ok -> IO.puts("Saved #{length(data)} data to #{file}")
      {:error, reason} -> IO.puts("Failed to save file: #{reason}")
    end
  end
end
