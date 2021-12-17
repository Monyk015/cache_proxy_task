defmodule CacheProxy.CacheTest do
  use ExUnit.Case, async: false
  alias CacheProxy.Cache
  import Mock

  test "get something that isn't cached" do
    assert :not_found = Cache.get("nonexistent_key")
  end

  test "insert and get a fresh result" do
    assert :ok == Cache.insert("some_url", %{result: true})
    assert {:ok, :fresh, result} = Cache.get("some_url")
    assert %{result: true} == result
  end

  test "insert and get a stale result" do
    approx_timestamp = Cache.now()
    :ok = Cache.insert("some_other_url", %{result: true})

    with_mock(Cache, [:passthrough],
      now: fn ->
        approx_timestamp + 24 * 60 * 60 + 1
      end
    ) do
      assert {:ok, :stale, result} = Cache.get("some_other_url")
      assert %{result: true} == result
    end
  end
end
