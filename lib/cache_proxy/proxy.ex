defmodule CacheProxy.Proxy do
  alias CacheProxy.Cache
  alias __MODULE__

  @successful_responses [200, 201, 202, 203, 204, 205, 206]

  def get(url) do
    case Cache.get(url) do
      :not_found ->
        case Proxy.http_request(url) do
          {:ok, res} ->
            Cache.insert(url, res)
            {:ok, res}

          {:error, error} ->
            {:error, error}
        end

      {:ok, :stale, result} ->
        case Proxy.http_request(url) do
          {:ok, res} ->
            :ok = Cache.insert(url, res)
            {:ok, res}

          {:error, _error} ->
            {:ok, result}
        end

      {:ok, :fresh, result} ->
        {:ok, result}
    end
  end

  def http_request(url) do
    case Tesla.get(url) do
      {:ok, env} when env.status in @successful_responses -> {:ok, env}
      {:ok, env} -> {:error, env}
      {:error, tesla_error} -> {:error, tesla_error}
    end
  end
end
