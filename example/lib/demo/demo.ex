defmodule Demo do
  @moduledoc false

  @doc """
  Add 1 to the `value` in NIF and send the intermediate result to
  Elixir for further processing using the `callback` function.

  The result of the `callback` function is returned as the final result.

  ## Example

      iex> Demo.add_one(1, fn result -> result * 2 end)
      4

  ## Example when the callback function throws an exception

      iex> Demo.add_one(1, fn val ->
      ...>   throw {val, :oh_nooooo}
      ...> end)
      {:throw, {2, :oh_nooooo}}

  ## Examples when the callback function raises an exception

      iex> Demo.add_one(1, fn val ->
      ...>   raise RuntimeError, "cannot use this value: \#{val}"
      ...> end)
      {:error, %RuntimeError{message: "cannot use this value: 2"}}

  """
  def add_one(value, callback) do
    NifCall.run(Demo.Runner, callback, fn tag ->
      Demo.NIF.add_one(value, tag)
    end)
  end

  @doc """
  Send an initial value to NIF and NIF will send intermediate results to
  the `callback` function in Elixir. This function returns either

  - `{:cont, new_value}` to continue the iteration in NIF with the new value
  - `{:done, result}` to indicate the NIF to stop the iteration and return the final result

  In this demo, the NIF function will multiply the value by 2 in each iteration, and
  we further add 1 to every intermediate result in the callback unless the intermediate
  result is greater than 42.

  ## Examples

      iex> Demo.iterate(1, fn
      ...>   val when val <= 42 ->
      ...>     {:cont, val + 1}
      ...>   val ->
      ...>     {:done, val}
      ...> end)
      62

  """
  def iterate(initial_value, callback) do
    NifCall.run(Demo.Runner, callback, fn tag ->
      Demo.NIF.iterate(initial_value, tag)
    end)
  end
end
