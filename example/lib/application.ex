defmodule NifCall.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Foo.Evaluator, [nif: Foo.NIF, process_options: [name: Foo.Evaluator]]}
    ]

    opts = [strategy: :one_for_one, name: Foo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
