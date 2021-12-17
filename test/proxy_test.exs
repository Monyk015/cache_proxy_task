defmodule CacheProxy.ProxyTest do
  use ExUnit.Case, async: false
  alias CacheProxy.Proxy
  import Mock
  alias CacheProxy.Cache
  @valid_response %Tesla.Env{status: 200, body: "body"}

  @example_url "http://example.com/list"
  test "2 requests to get should only trigger http request once" do
    with_mock(Proxy, [:passthrough],
      http_request: fn _ ->
        {:ok, @valid_response}
      end
    ) do
      assert {:ok, res} = Proxy.get(@example_url)
      assert %{body: "body"} = res
      assert {:ok, res2} = Proxy.get(@example_url)
      assert res == res2
      assert_called_exactly(Proxy.http_request(@example_url), 1)
    end
  end

  @url "http://some.url"
  test "should return stale response if actual http response fails" do
    with_mocks([
      {Proxy, [:passthrough],
       http_request: fn _ ->
         {:error, %Tesla.Env{status: 404, body: "not found"}}
       end},
      {Cache, [], get: fn _ -> {:ok, :stale, @valid_response} end}
    ]) do
      assert {:ok, res} = Proxy.get(@url)
      assert %{body: body} = res
      assert_called_exactly(CacheProxy.Cache.get(@url), 1)
      assert_called_exactly(Proxy.http_request(@url), 1)
    end
  end

  test "should return new response if there it works ok but there is a stale result" do
    with_mocks([
      {Proxy, [:passthrough],
       http_request: fn _ ->
         {:ok, %Tesla.Env{status: 200, body: "new body"}}
       end},
      {Cache, [], get: fn _ -> {:ok, :stale, @valid_response} end, insert: fn _, _ -> :ok end}
    ]) do
      assert {:ok, res} = Proxy.get(@url)
      assert %{body: "new body"} = res
      assert_called_exactly(CacheProxy.Cache.get(@url), 1)

      assert_called_exactly(
        CacheProxy.Cache.insert(@url, %Tesla.Env{status: 200, body: "new body"}),
        1
      )

      assert_called_exactly(Proxy.http_request(@url), 1)
    end
  end
end
