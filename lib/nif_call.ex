defmodule NifCall do
  def run(name, to_be_called, fun) do
    tag = NifCall.Runner.register(name, to_be_called)

    try do
      fun.(tag)
    after
      NifCall.Runner.unregister(name, tag)
    end
  end
end
