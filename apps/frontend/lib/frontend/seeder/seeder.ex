defmodule Frontend.Seeder.Seeder do
  @moduledoc """
  This module fetches and downloads images from the Rick and Morty API.
  It uses Req for HTTP requests and Jason for JSON encoding/decoding.
  """
  alias Frontend.RickAndMortyImageFetcher.Downloader
  require Logger
  @base_url "https://rickandmortyapi.com/api/character/avatar"
  @save_dir Path.join([:code.priv_dir(:frontend), "static", "images", "rick_and_morty_avatars"])

  def download_all_images do
    with :ok <- File.mkdir_p(@save_dir),
         total when total > 0 <- fetch_total_characters() do
      1..total
      |> Task.async_stream(
        fn id ->
          :timer.sleep(400)
          download(id, @base_url, @save_dir)
        end,
        max_concurrency: 10,
        timeout: 30_000
      )
      |> Stream.run()

      Logger.info("🎉 All images downloaded!")
    else
      {:error, reason} ->
        Logger.error("❌ Failed to create directory #{@save_dir}: #{inspect(reason)}")

      total when total <= 0 ->
        Logger.error("❌ Failed to fetch total characters. No images downloaded.")
    end
  end

  defp fetch_total_characters do
    url = "https://rickandmortyapi.com/api/character"

    case Req.get(url) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        # dbg(body, label: "API Response Body")
        %{"info" => %{"count" => count}} = body
        count

      {:error, reason} ->
        Logger.error("❌ HTTP request failed: #{inspect(reason)}")
        0

      _ ->
        Logger.error("❌ Unexpected error fetching total characters")
        0
    end
  end

  def download(id, base_url, save_dir, retries \\ 3) do
    url = "#{base_url}/#{id}.jpeg"
    file_path = Path.join(save_dir, "#{id}.jpeg")

    case Req.get(url) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        File.write!(file_path, body)
        Logger.info("✅ Downloaded #{id}")

      {:ok, %Req.Response{status: status}} ->
        Logger.error("⚠️  Failed #{id}: Status #{status}")
        if retries > 0, do: download(id, base_url, save_dir, retries - 1)

      {:error, reason} ->
        Logger.error("❌ Error downloading #{id}: #{inspect(reason)}")
        if retries > 0, do: download(id, base_url, save_dir, retries - 1)
    end
  end

  defmodule Downloader do
    @moduledoc """
    This module handles the downloading of images from the Rick and Morty API.
    """
  end
end
