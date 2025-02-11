defmodule NifCall do
  def run(name, to_be_called, fun) do
    tag = NifCall.Runner.register(name, to_be_called)

    fun.(tag)
  end
end
