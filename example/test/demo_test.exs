defmodule DemoTest do
  use ExUnit.Case
  doctest Demo, except: [iterate: 2]
end
