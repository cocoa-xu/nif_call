defmodule NifCall.Runner do
  use GenServer

  defstruct [:nif_module, :on_evaluated, :refs]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts[:runner_opts], opts)
  end

  def register(name, function) when is_function(function, 1) do
    GenServer.call(name, {:register, self(), function}, :infinity)
  end

  def unregister(name, {_pid, ref}) do
    GenServer.call(name, {:unregister, ref}, :infinity)
  end

  def init(opts) do
    opts = Keyword.validate!(opts, [:nif_module, on_evaluated: :nif_call_evaluated])
    {:ok, %__MODULE__{nif_module: opts[:nif_module], on_evaluated: opts[:on_evaluated], refs: %{}}}
  end

  def handle_call({:register, owner, function}, _from, state) do
    ref = Process.monitor(owner)
    {:reply, {self(), ref}, %{state | refs: Map.put(state.refs, ref, function)}}
  end

  def handle_call({:unregister, ref}, _from, state) do
    Process.demonitor(ref, [:flush])
    {:reply, :ok, %{state | refs: Map.delete(state.refs, ref)}}
  end

  def handle_info({:DOWN, ref, _, _, _}, state) do
    {:noreply, %{state | refs: Map.delete(state.refs, ref)}}
  end

  def handle_info({:execute, resource, ref, args}, state) do
    function = Map.fetch!(state.refs, ref)

    pid = spawn(fn ->
      try do
        apply(state.nif_module, state.on_evaluated, [resource, {:ok, apply(function, List.wrap(args))}])
      catch
        kind, reason ->
          apply(state.nif_module, state.on_evaluated, [resource, {kind, reason}])
      end
    end)

    _ = Process.monitor(pid, tag: {:eval, resource})
    {:noreply, state}
  end

  def handle_info({{:eval, resource}, _, _, _, reason}, state) do
    if reason != :normal do
      apply(state.nif_module, :nif_call_evaluated, [resource, {:exit, reason}])
    end

    {:noreply, state}
  end
end
