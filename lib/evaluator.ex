defmodule NifCall.Evaluator do
  @moduledoc false

  defmacro __using__(using_opts) do
    on_evaluated = Keyword.get(using_opts, :on_evaluated, :nif_call_evaluated)

    quote do
      use GenServer

      def start_link(opts), do: GenServer.start_link(__MODULE__, opts, opts[:process_options])

      @impl GenServer
      def init(opts), do: {:ok, opts[:nif_module]}

      @impl GenServer
      def handle_info({callback, args, from_ref}, nif_module) when is_function(callback) do
        apply(nif_module, unquote(on_evaluated), [from_ref, apply(callback, List.wrap(args))])
        {:noreply, nif_module}
      end
    end
  end
end
