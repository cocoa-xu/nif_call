defmodule NifCall.NIF do
  @moduledoc false

  defmacro __using__(opts) do
    funcname = Keyword.get(opts, :funcname, :elixir_call_evaluated)
    quote do
      def unquote(funcname)(_from_ref, _results), do: :erlang.nif_error(:not_loaded)
    end
  end
end
