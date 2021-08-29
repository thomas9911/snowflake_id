# SnowflakeId

[Snowflake Identifier](https://en.wikipedia.org/wiki/Snowflake_ID) in Elixir, based on Rust's [rs-snowflake](https://crates.io/crates/rs-snowflake)

Generates SnowflakeId's. This struct implements the `Enumerable` protocol,
so you can use this with all the functions from `Enum` and `Stream` modules.

This implementation is functional and does not use any GenServer to store the state.

```elixir
# override the time function for the test
iex> get_time = fn -> 1630163558780 end
iex> generator = SnowflakeId.new(1, 1, get_time: get_time)
iex> Enum.at(generator, 0)
6837401535245324288
iex> generator |> Enum.at(0) |> Integer.to_string(2)
"101111011100011010101000111100001011111000000100001000000000000"
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^xxxxxyyyyyzzzzzzzzzzzz
#^: timestamp
#x: machine_id
#y: node_id
#z: index
```

More realistic example:

```elixir
iex> my_data =
...>   SnowflakeId.new(1, 1)
...>   |> Enum.take(10)
...>   |> Enum.map(fn id ->
...>     # insert your data in your database
...>     %{id: id, name: "my_id_#{id}"}
...>   end)
iex> length(my_data)
10
```

If you want to not use the `Enumerable` protocol you can do it yourself by:

```elixir
# override the time function for the test
iex> get_time = fn -> 1630163558780 end
iex> generator = SnowflakeId.new(1, 1, get_time: get_time)
iex> SnowflakeId.format_id(generator)
6837401535245324288
iex> generator = SnowflakeId.next(generator)
iex> SnowflakeId.format_id(generator)
6837401535245324289
```

Small warning, because the timestamp only uses 41 bits and the default timestamp starts from 1970. The maximum time that can be stored is:

```elixir
iex> bits = 0b11111111111111111111111111111111111111111
iex> DateTime.from_unix(bits, :millisecond)
{:ok, ~U[2039-09-07 15:47:35.551Z]}
```

You can mitigate this by using your own timestamp function or use the helper function:

```elixir
# from the start of 2000
iex> from = ~U[2000-01-01T00:00:00Z]
iex> get_time = SnowflakeId.timestamp_factory(from)
iex> with_own_get_time = SnowflakeId.new(1, 1, get_time: get_time)
iex> default_get_time = SnowflakeId.new(1, 1)
iex> Enum.at(with_own_get_time, 0) < Enum.at(default_get_time, 0)
true
```

we can now use this longer:

```elixir
iex> bits = 0b11111111111111111111111111111111111111111
iex> ~U[2000-01-01T00:00:00Z] |> DateTime.add(bits, :millisecond) |> DateTime.truncate(:second)
~U[2069-09-06 15:47:35Z]
```

## Installation

```elixir
def deps do
  [
    {:snowflake_id, "~> 0.1.0"}
  ]
end
```

## Documentation

[https://hexdocs.pm/snowflake_id](https://hexdocs.pm/snowflake_id)
