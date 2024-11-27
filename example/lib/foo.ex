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
    NifCall.Evaluator.elixir_callback(fn b, c ->
      # `a` and `cb` are captured from the outer scope
      # `b` and `c` are the arguments passed from `NifCall.Evaluator.elixir_callback/2`
      Foo.NIF.compute(a, b + c, cb)
    end, [2, 3])
  end

  def demo do
    compute(1, fn result -> IO.puts("Result: #{result}") end)
  end
end
