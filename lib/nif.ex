defmodule NifCall.NIF do
  @moduledoc false

  defmacro __using__(using_opts) do
    funcname = Keyword.get(using_opts, :on_evaluated, :nif_call_evaluated)

    quote do
      def unquote(:"#{funcname}")(_from_ref, _results), do: :erlang.nif_error(:not_loaded)
    end
  end
end
