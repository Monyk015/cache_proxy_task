defmodule CacheProxy.Cache do
  use GenServer
  alias __MODULE__
  @table_name :cached_responses
  @process_name __MODULE__
  @timeout 24 * 60 * 60

  @impl true
  def init(_) do
    :ets.new(@table_name, [:set, :private, :named_table])

    {:ok, []}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: @process_name)
  end

  @impl true
  def handle_call({:get, key}, _, _) do
    result =
      case :ets.lookup(@table_name, key) do
        [] ->
          :not_found

        [{^key, value, timestamp}] ->
          if Cache.now() - timestamp < @timeout,
            do: {:ok, :fresh, value},
            else: {:ok, :stale, value}
      end

    {:reply, result, []}
  end

  @impl true
  def handle_call({:insert, key, value}, _, _) do
    timestamp = Cache.now()
    true = :ets.insert(@table_name, {key, value, timestamp})
    {:reply, :ok, []}
  end

  def get(key) do
    GenServer.call(@process_name, {:get, key})
  end

  def insert(key, result) do
    GenServer.call(@process_name, {:insert, key, result})
  end

  def now, do: DateTime.to_unix(DateTime.utc_now())
end
