# ##### With input Bigger (100_000) #####
# Name               ips        average  deviation         median         99th %
# integers        516.33        1.94 ms    ±17.58%        1.84 ms        3.83 ms
# bulk             35.02       28.56 ms     ±9.88%       27.75 ms       45.55 ms
# normal           24.73       40.44 ms     ±8.57%       39.53 ms       64.38 ms

# Comparison:
# integers        516.33
# bulk             35.02 - 14.74x slower +26.62 ms
# normal           24.73 - 20.88x slower +38.50 ms

# ##### With input Medium (1000) #####
# Name               ips        average  deviation         median         99th %
# integers       48.37 K       20.67 μs    ±30.72%       20.47 μs       40.95 μs
# bulk            3.06 K      327.04 μs    ±25.24%      307.19 μs      614.39 μs
# normal          2.25 K      443.82 μs    ±20.51%      409.59 μs      716.79 μs

# Comparison:
# integers       48.37 K
# bulk            3.06 K - 15.82x slower +306.36 μs
# normal          2.25 K - 21.47x slower +423.15 μs

# ##### With input Small (10) #####
# Name               ips        average  deviation         median         99th %
# integers     2634.93 K        0.38 μs   ±131.09%           0 μs        1.01 μs
# bulk          276.82 K        3.61 μs    ±21.72%        3.06 μs        6.13 μs
# normal        199.89 K        5.00 μs    ±17.34%        5.11 μs        8.18 μs

# Comparison:
# integers     2634.93 K
# bulk          276.82 K - 9.52x slower +3.23 μs
# normal        199.89 K - 13.18x slower +4.62 μs

# integers can loop through 50_000_000 numbers a second
# SnowflakeId with bulk option can loop through 3_500_000 numbers a second
# SnowflakeId can loop through 2_500_000 numbers a second



# We use the Enum.reduce_while here, instead of Enum.at(amount), 
# because Range will use an optimized version and SnowflakeId doesn't have this

Benchee.run(
  %{
    "integers" => fn amount ->
      0..amount
      |> Enum.reduce_while(0, fn _, acc ->
        if acc < amount do
          {:cont, acc + 1}
        else
          {:halt, acc}
        end
      end)
    end,
    "bulk" => fn amount ->
      SnowflakeId.new(1, 1, bulk: true)
      |> Enum.reduce_while(0, fn _, acc ->
        if acc < amount do
          {:cont, acc + 1}
        else
          {:halt, acc}
        end
      end)
    end,
    "normal" => fn amount ->
      SnowflakeId.new(1, 1)
      |> Enum.reduce_while(0, fn _, acc ->
        if acc < amount do
          {:cont, acc + 1}
        else
          {:halt, acc}
        end
      end)
    end
  },
  inputs: %{
    "Small (10)" => 10,
    "Medium (1000)" => 1000,
    "Bigger (100_000)" => 100_000
  }
)


