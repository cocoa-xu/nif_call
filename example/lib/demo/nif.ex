defmodule Demo.NIF do
  @moduledoc false

  use NifCall.NIF, on_evaluated: :nif_call_evaluated

  @on_load :load_nif
  def load_nif do
    nif_file = ~c"#{:code.priv_dir(:demo)}/nif"

    case :erlang.load_nif(nif_file, 0) do
      :ok -> :ok
      {:error, {:reload, _}} -> :ok
      {:error, reason} -> IO.puts("Failed to load nif: #{inspect(reason)}")
    end
  end

  def add_one(_arg, _tag), do: :erlang.nif_error(:not_loaded)
  def iterate(_arg, _tag), do: :erlang.nif_error(:not_loaded)
  def callback_throws(_arg, _tag), do: :erlang.nif_error(:not_loaded)
end
