defmodule Demo.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {NifCall.Runner,
       runner_opts: [nif_module: Demo.NIF, on_evaluated: :nif_call_evaluated], name: Demo.Runner}
    ]

    opts = [strategy: :one_for_one, name: Demo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
