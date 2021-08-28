defmodule SnowflakeId do
  @moduledoc ~S"""
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

  """

  @type t :: %__MODULE__{
          node_id: integer,
          machine_id: integer,
          idx: integer,
          last_time_millis: integer,
          get_time: (() -> integer),
          bulk: boolean
        }

  @type opts :: [
    bulk: boolean,
    get_time: (-> integer)
  ]

  use Bitwise

  defstruct [:node_id, :machine_id, :idx, :last_time_millis, :get_time, bulk: false]

  @doc """
  Create a new `SnowflakeId` struct

  options:
  - :get_time : (-> integer)
    override the function to get the current timestamp, 
    this function should return the time since an epoch in milliseconds.
    by defaut it uses `:os.system_time(:millisecond)`

  - :bulk : boolean
    Don't check the time on every iteration, but only when the maximum amount of indexes is filled, which is `0..4095`
    This can be handy if you know you are going to generate a lot of indexes at once.

  """
  @spec new(integer, integer) :: t()
  @spec new(integer, integer, opts) :: t()
  def new(machine_id, node_id, opts \\ []) do
    f = Keyword.get(opts, :get_time, &os_system_time/0)

    %SnowflakeId{
      machine_id: machine_id,
      node_id: node_id,
      idx: 0,
      last_time_millis: f.(),
      get_time: f,
      bulk: Keyword.get(opts, :bulk, false)
    }
  end

  @doc """
  Create a new `SnowflakeId` struct but with some extra checks. For more info check `new/3`
  """
  @spec try_new(integer, integer) :: {:ok, t()} | {:error, atom}
  @spec try_new(integer, integer, opts) :: {:ok, t()} | {:error, atom}
  def try_new(machine_id, node_id, opts \\ [])

  def try_new(machine_id, _, _) when machine_id > 31 do
    {:error, :machine_id_too_large}
  end

  def try_new(machine_id, _, _) when machine_id < 0 do
    {:error, :machine_id_too_small}
  end

  def try_new(_, node_id, _) when node_id > 31 do
    {:error, :node_id_too_large}
  end

  def try_new(_, node_id, _) when node_id < 0 do
    {:error, :node_id_too_small}
  end

  def try_new(machine_id, node_id, opts) do
    {:ok, new(machine_id, node_id, opts)}
  end

  @doc """
  Default function to return the current timestamp in milliseconds
  """
  @spec os_system_time :: integer
  def os_system_time do
    :os.system_time(:millisecond)
  end

  @doc """
  Format the struct to return a id
  """
  @spec format_id(t()) :: integer
  def format_id(%__MODULE__{
        node_id: node_id,
        machine_id: machine_id,
        idx: idx,
        last_time_millis: last_time_millis
      }) do
    last_time_millis <<< 22 |||
      machine_id <<< 17 |||
      node_id <<< 12 |||
      idx
  end

  @doc """
  Update the struct to the next identifier
  """
  @spec next(t()) :: t()
  def next(
        %__MODULE__{
          idx: idx,
          last_time_millis: last_time_millis,
          get_time: get_time,
          bulk: true
        } = state
      )
      when idx > 4094 do
    new_time = get_time.()

    if new_time == last_time_millis do
      # loop until it is the next millisecond
      next(state)
    else
      state
      |> Map.put(:last_time_millis, new_time)
      |> Map.put(:idx, 0)
    end
  end

  def next(%__MODULE__{bulk: true} = state) do
    Map.update!(state, :idx, fn x -> x + 1 end)
  end

  def next(
        %__MODULE__{
          idx: idx,
          last_time_millis: last_time_millis,
          get_time: get_time
        } = state
      ) do
    new_time = get_time.()

    cond do
      new_time == last_time_millis and idx < 4095 ->
        Map.update!(state, :idx, fn x -> x + 1 end)

      new_time == last_time_millis ->
        next(state)

      true ->
        state
        |> Map.put(:last_time_millis, new_time)
        |> Map.put(:idx, 0)
    end
  end
end

defimpl Enumerable, for: SnowflakeId do
  def count(_function), do: {:error, __MODULE__}
  def member?(_function, _value), do: {:error, __MODULE__}
  def slice(_function), do: {:error, __MODULE__}

  def reduce(_, {:halt, acc}, _fun), do: {:halted, acc}
  def reduce(n, {:suspend, acc}, fun), do: {:suspended, acc, &reduce(n, &1, fun)}

  def reduce(state, {:cont, acc}, fun) do
    id = SnowflakeId.format_id(state)
    state = SnowflakeId.next(state)
    reduce(state, fun.(id, acc), fun)
  end
end
