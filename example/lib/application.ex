defmodule NifCall.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {NifCall.Evaluator, []}
    ]

    opts = [strategy: :one_for_one, name: NifCall.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
