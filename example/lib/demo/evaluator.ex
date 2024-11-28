defmodule Demo.Evaluator do
  use NifCall.Evaluator, on_evaluated: :nif_call_evaluated
end
