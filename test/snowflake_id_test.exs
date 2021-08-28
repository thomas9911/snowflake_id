defmodule SnowflakeIdTest do
  use ExUnit.Case
  doctest SnowflakeId

  def split_into_timestamp_and_index(id) do
    timestamp = id |> Bitwise.bsr(22) |> Integer.to_string(2)
    id_with_node_id_part = id |> Integer.mod(0b1000000000000000) |> Integer.to_string(2)
    {timestamp, id_with_node_id_part}
  end

  test "SnowflakeId works" do
    get_time = fn -> 1_630_163_558_780 end
    generator = SnowflakeId.new(1, 1, get_time: get_time)
    assert 6_837_401_535_245_324_288 == Enum.at(generator, 0)
  end

  test "try new ok" do
    assert {:ok, %SnowflakeId{}} = SnowflakeId.try_new(10, 4)
  end

  test "try new machine error" do
    assert {:error, :machine_id_too_large} = SnowflakeId.try_new(100, 1)
    assert {:error, :machine_id_too_small} = SnowflakeId.try_new(-500, 1)
  end

  test "try new node error" do
    assert {:error, :node_id_too_large} = SnowflakeId.try_new(1, 10_000)
    assert {:error, :node_id_too_small} = SnowflakeId.try_new(1, -8)
  end

  test "try new both error" do
    assert {:error, :machine_id_too_large} = SnowflakeId.try_new(100, 1000)
    assert {:error, :machine_id_too_small} = SnowflakeId.try_new(-9, -85)
  end

  test "enum works" do
    list_of_ids = SnowflakeId.new(3, 2) |> Enum.take(20)

    assert length(list_of_ids) == 20
  end

  test "stream works" do
    list_of_ids =
      SnowflakeId.new(3, 2)
      |> Stream.cycle()
      |> Stream.take(30)
      |> Stream.uniq()
      |> Enum.to_list()

    assert length(list_of_ids) == 30
  end

  test "format_id works" do
    id = SnowflakeId.new(3, 2) |> Map.put(:last_time_millis, 50) |> SnowflakeId.format_id()

    parts = ["00000000000000000000000000000000000110010", "00011", "00010", "000000000000"]

    assert id == parts |> Enum.join() |> String.to_integer(2)
  end

  describe "Enumerable" do
    setup do
      init = %{counter: 0, time: 5000}
      {:ok, pid} = Agent.start_link(fn -> init end)

      get_time_factory = fn amount ->
        fn ->
          Agent.get_and_update(pid, fn %{counter: counter, time: time} ->
            if counter > amount do
              {time + 1, %{counter: 0, time: time + 1}}
            else
              {time, %{counter: counter + 1, time: time}}
            end
          end)
        end
      end

      reset = fn ->
        Agent.update(pid, fn _ -> init end)
      end

      on_exit(fn ->
        try do
          Agent.stop(pid)
        catch
          # throws exit exception if agent is already stopped
          :exit, _ ->
            :ok
        end
      end)

      {:ok, %{get_time_factory: get_time_factory, reset: reset}}
    end

    test "sanity check: agent works", %{get_time_factory: get_time_factory, reset: reset} do
      assert [5000, 5000, 5001, 5001] ==
               Enum.map(0..5002, fn _ -> get_time_factory.(5000).() end) |> Enum.slice(4999..5002)

      reset.()

      assert [5000, 5000, 5001, 5001] ==
               Enum.map(0..50, fn _ -> get_time_factory.(20).() end) |> Enum.slice(19..22)
    end

    test "SnowflakeId does not overflow id and waits till next millisecond", %{
      get_time_factory: get_time_factory
    } do
      ids =
        SnowflakeId.new(21, 5, get_time: get_time_factory.(5000))
        |> Enum.take(6000)
        |> Enum.slice(4094..4098)
        |> Enum.map(&split_into_timestamp_and_index/1)

      assert [
               {"1001110001000", "101111111111110"},
               {"1001110001000", "101111111111111"},
               {"1001110001001", "101000000000000"},
               {"1001110001001", "101000000000001"},
               {"1001110001001", "101000000000010"}
             ] == ids
    end

    test "SnowflakeId does not overflow id and waits till next millisecond when bulk true", %{
      get_time_factory: get_time_factory
    } do
      ids =
        SnowflakeId.new(21, 5, bulk: true, get_time: get_time_factory.(20))
        |> Enum.take(6000)
        |> Enum.slice(4094..4098)
        |> Enum.map(&split_into_timestamp_and_index/1)

      assert [
               {"1001110001000", "101111111111110"},
               {"1001110001000", "101111111111111"},
               {"1001110001001", "101000000000000"},
               {"1001110001001", "101000000000001"},
               {"1001110001001", "101000000000010"}
             ] == ids
    end
  end
end
