defmodule Frontend.PlotStore.Store do
  use GenServer

  @moduledoc """
  A GenServer to manage Rick and Morty plots.
  Keys are structured as "season_episode" (e.g., "01_01").
  """

  # Client API

  @doc """
  Starts the GenServer.
  """
  def start_link(initial_state \\ %{}) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  @doc """
  Adds a new plot to the server. Returns `:ok` if the plot is added or `{:error, reason}` if the key already exists.

  ## Parameters:
  - key: The key as a string (e.g., "01_01").
  - plot: The plot as a string.
  """
  def add_plot(key, plot) when is_binary(key) and is_binary(plot) do
    GenServer.call(__MODULE__, {:add_plot, key, plot})
  end

  @doc """
  Retrieves the plot for the given key. Returns `{:ok, plot}` if the key exists or `{:error, :not_found}` if it doesn't.

  ## Parameters:
  - key: The key as a string (e.g., "01_01").
  """
  def get_plot(key) when is_binary(key) do
    GenServer.call(__MODULE__, {:get_plot, key})
  end

  def list_plot() do
    GenServer.call(__MODULE__, {:list_plot})
  end

  @doc """
  Clears all plots from the server, resetting the state to an empty map.
  """
  def clear_plots() do
    GenServer.call(__MODULE__, :clear_plots)
  end

  # Server Callbacks

  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  def handle_call({:add_plot, key, plot}, _from, state) do
    if Map.has_key?(state, key) do
      {:reply, {:error, :key_already_exists}, state}
    else
      new_state = Map.put(state, key, plot)
      {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call({:get_plot, key}, _from, state) do
    case Map.get(state, key) do
      nil -> {:reply, {:error, :not_found}, state}
      plot -> {:reply, {:ok, plot}, state}
    end
  end

  @impl true
  def handle_call({:list_plot}, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_call(:clear_plots, _from, _state) do
    {:reply, :ok, %{}}
  end
end
