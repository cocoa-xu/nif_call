defmodule NifCall.Runner do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def register(name, function) when is_function(function, 1) do
    GenServer.call(name, {:register, self(), function}, :infinity)
  end

  def unregister(name, {_pid, ref}) do
    GenServer.call(name, {:unregister, ref}, :infinity)
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:register, owner, function}, _from, state) do
    ref = Process.monitor(owner)
    {:reply, {self(), ref}, Map.put(state, ref, function)}
  end

  def handle_call({:unregister, ref}, _from, state) do
    Process.demonitor(ref, [:flush])
    {:reply, :ok, Map.delete(state, ref)}
  end

  def handle_info({:DOWN, ref, _, _, _}, state) do
    {:noreply, Map.delete(state, ref)}
  end

  def handle_info({:execute, resource, ref, arg}, state) do
    function = Map.fetch!(state, ref)

    pid = spawn(fn ->
      try do
        NifCall.NIF.back_to_c(resource, {:ok, function.(arg)})
      catch
        kind, reason -> NifCall.NIF.back_to_c(resource, {kind, reason})
      end
    end)

    _ = Process.monitor(pid, tag: {:eval, resource})
    {:noreply, state}
  end

  def handle_info({{:eval, resource}, _, _, _, reason}, state) do
    if reason != :normal do
      NifCall.NIF.back_to_c(resource, {:exit, reason})
    end

    {:noreply, state}
  end
end
