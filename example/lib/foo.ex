defmodule Foo do
  @moduledoc false

  @doc """
  Do some operation in NIF and send the intermediate result to
  Elixir for further processing, then send the final result back
  to NIF.

  ## Examples

      iex> Foo.compute(1, fn result -> result * 2 end)
      10

  """
  def compute(a, cb) do
    Foo.NIF.compute_with_evaluator(a, 1, Process.whereis(NifCall.Evaluator), cb)
  end

  def demo do
    compute(1, fn result ->
      IO.puts("Result: #{result}")
      result * 2
    end)
  end
end
