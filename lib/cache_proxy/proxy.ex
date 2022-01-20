defmodule CacheProxy.Proxy do
  alias CacheProxy.Cache
  alias __MODULE__

  @successful_responses [200, 201, 202, 203, 204, 205, 206]

  defp get_and_insert(url, default \\ nil) do
    case Proxy.http_request(url) do
      {:ok, res} ->
        Cache.insert(url, res)
        {:ok, res}

      {:error, _error} when default == nil ->
        {:ok, default}

      {:error, error} ->
        {:error, error}
    end
  end

  def get(url) do
    case Cache.get(url) do
      :not_found ->
        get_and_insert(url)

      {:ok, :stale, result} ->
        get_and_insert(url, result)

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
