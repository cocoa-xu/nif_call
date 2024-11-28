defmodule Foo do
  @moduledoc false

  @doc """
  Do some operation in NIF and send the intermediate result to
  Elixir for further processing, then send the final result back
  to NIF.

  ## Examples

      iex> Foo.compute(1, fn result -> result * 2 end)
      4

  """
  def compute(value, callback) do
    Foo.NIF.compute(value, Process.whereis(Foo.Evaluator), callback)
  end

  def demo do
    compute(1, &(&1 * 2))
  end
end
