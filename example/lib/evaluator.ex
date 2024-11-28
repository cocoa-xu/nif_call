defmodule NifCall.Evaluator do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      use GenServer

      def start_link(opts), do: GenServer.start_link(__MODULE__, opts, opts[:process_options])

      @impl GenServer
      def init(opts), do: {:ok, opts[:nif]}

      @impl GenServer
      def handle_info({callback, args, from_ref}, nif_module) when is_function(callback) do
        nif_module.elixir_call_evaluated(from_ref, apply(callback, List.wrap(args)))
        {:noreply, nif_module}
      end
    end
  end
end
