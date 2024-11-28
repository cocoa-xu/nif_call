defmodule Foo.NIF do
  @moduledoc false

  @on_load :load_nif
  def load_nif do
    nif_file = ~c"#{:code.priv_dir(:nif_call)}/nif"

    case :erlang.load_nif(nif_file, 0) do
      :ok -> :ok
      {:error, {:reload, _}} -> :ok
      {:error, reason} -> IO.puts("Failed to load nif: #{inspect(reason)}")
    end
  end

  def compute(_arg1, _arg2, _mf), do: :erlang.nif_error(:not_loaded)
  def compute_with_evaluator(_arg1, _arg2, _evaluator, _mf), do: :erlang.nif_error(:not_loaded)
  def evaluated(_from_ref, _results), do: :erlang.nif_error(:not_loaded)
end
