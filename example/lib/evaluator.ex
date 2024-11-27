defmodule NifCall.Evaluator do
  @moduledoc false

  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, nil, name: opts[:name] || __MODULE__)
  end


  @impl GenServer
  def init(_) do
    {:ok, nil}
  end

  def elixir_callback(pid \\ __MODULE__, wrapped_function, args) do
    GenServer.call(pid, {:call, wrapped_function, args})
  end

  @impl GenServer
  def handle_call({:call, wrapped_function, args}, from, state) do
    result = apply(wrapped_function, args)
    {:reply, result, state}
  end

  @impl GenServer
  def handle_info({{module, function}, args, from_ref}, state) when is_atom(module) and is_atom(function) do
    Logger.info("Evaluating #{module}.#{function} with args #{inspect(args)}")
    results = apply(module, function, List.wrap(args))
    Foo.NIF.evaluated(from_ref, results)
    {:noreply, state}
  end

  def handle_info({callback, args, from_ref}, state) when is_function(callback) do
    Logger.info("Evaluating callback with args #{inspect(args)}")
    results = apply(callback, List.wrap(args))
    Foo.NIF.evaluated(from_ref, results)
    {:noreply, state}
  end
end
