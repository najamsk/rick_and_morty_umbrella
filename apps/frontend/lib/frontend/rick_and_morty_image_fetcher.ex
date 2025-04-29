defmodule Frontend.RickAndMortyImageFetcher do
  @base_url "https://rickandmortyapi.com/api/character/avatar"
  # @save_dir Path.join(:code.priv_dir(:frontend), ["static", "images", "rick_and_morty_avatars"])
  # @save_dir Path.join(:code.priv_dir(:frontend), ["static", "images", "rick_and_morty_avatars"])
  @save_dir Path.join([:code.priv_dir(:frontend), "static", "images", "rick_and_morty_avatars"])

  def download_all_images do
    case File.mkdir_p(@save_dir) do
      :ok ->
        total_characters = fetch_total_characters()

        if total_characters > 0 do
          1..total_characters
          |> Task.async_stream(
            fn id ->
              # Add a small delay
              :timer.sleep(100)
              Frontend.RickAndMortyImageFetcher.Downloader.download(id, @base_url, @save_dir)
            end,
            max_concurrency: 10,
            timeout: 30_000
          )
          |> Enum.to_list()

          IO.puts("🎉 All images downloaded!")
        else
          IO.puts("❌ Failed to fetch total characters. No images downloaded.")
        end

      {:error, reason} ->
        IO.puts("❌ Failed to create directory #{@save_dir}: #{inspect(reason)}")
    end
  end

  defp fetch_total_characters do
    case HTTPoison.get("https://rickandmortyapi.com/api/character") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        %{"info" => %{"count" => count}} = Jason.decode!(body)
        count

      {:error, reason} ->
        IO.inspect(reason, label: "Failed to fetch total characters")
        0
    end
  end

  defmodule Downloader do
    def download(id, base_url, save_dir, retries \\ 3) do
      url = "#{base_url}/#{id}.jpeg"
      file_path = Path.join(save_dir, "#{id}.jpeg")

      case HTTPoison.get(url) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          File.write!(file_path, body)
          IO.puts("✅ Downloaded #{id}")

        {:ok, %HTTPoison.Response{status_code: status}} ->
          IO.puts("⚠️  Failed #{id}: Status #{status}")
          if retries > 0, do: download(id, base_url, save_dir, retries - 1)

        {:error, reason} ->
          IO.puts("❌ Error downloading #{id}: #{inspect(reason)}")
          if retries > 0, do: download(id, base_url, save_dir, retries - 1)
      end
    end
  end
end
