# nif_call
Call Erlang/Elixir functions from NIF.

## Usage

### 1. Copy necessary files

1. Copy `nif.ex` and `evaluator.ex` to your Elixir project's `lib` directory (you can also put them in any subdirectory under `lib`). 
2. Copy `nif_call.h` to the `c_src` directory.

It may look like this when putting `.ex` files in the `lib/nif_call` directory:

```bash
.
├── Makefile
├── c_src
│   ├── demo_nif.cpp
│   └── nif_call.h          <-- From this repository
├── lib
│   ├── demo
│   │   ├── application.ex
│   │   └── demo.ex
│   └── nif_call
│       ├── evaluator.ex    <-- From this repository
│       └── nif.ex          <-- From this repository
├── mix.exs
└── mix.lock
```

### 2. Define Evaluator and NIF modules

Define an Evaluator module in your project. The Evaluator module is responsible for evaluating the Erlang/Elixir code. 

```elixir
defmodule Demo.Evaluator do
  use NifCall.Evaluator
end
```

To send the evaluated result back to the caller, `nif_call` needs to inject one NIF function to do that.

```elixir
defmodule Demo.NIF do
  use NifCall.NIF
end
```

The default name of this function is `nif_call_evaluated`. You can change it by passing the desired name to the `on_evaluated` option, like this:

```elixir
defmodule Demo.Evaluator do
  use NifCall.Evaluator, on_evaluated: :my_evaluated
end
```

```elixir
defmodule Demo.NIF do
  use NifCall.NIF, on_evaluated: :my_evaluated
end
```

### 3. Prepare C code

In your NIF code, include `nif_call.h` and define the `NIF_CALL_IMPLEMENTATION` macro before including it.

```c
#define NIF_CALL_IMPLEMENTATION
#include "nif_call.h"
```

And remember to initialize nif_call in the `onload` function.

```c
static int on_load(ErlNifEnv *env, void **, ERL_NIF_TERM) {
  // initialize nif_call
  return nif_call_onload(env);
}
```

Lastly, inject the NIF function:

```c
static ErlNifFunc nif_functions[] = {
  // ... your other NIF functions

  // inject nif_call functions
  // `nif_call_evaluated` is the name of the callback function that will be called by nif_call
  NIF_CALL_NIF_FUNC(nif_call_evaluated),

  // of course, you can change the name of the callback function
  // but remember to change it in the Elixir code as well
  // NIF_CALL_NIF_FUNC(my_evaluated),
};
```

### 4. Call Erlang/Elixir functions from NIF

Let's try to implement a simple function that adds 1 to the given value and sends the intermediate result to Elixir for further processing. The result of the Elixir callback function is returned as the final result.

First, we need to start the Evaluator process in the Elixir code.

```elixir
defmodule Demo.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Demo.Evaluator, [nif_module: Demo.NIF, process_options: [name: Demo.Evaluator]]}
    ]

    opts = [strategy: :one_for_one, name: Demo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Second, implement the `add_one` function in the Elixir code.

```elixir
defmodule Demo do
  @doc """
  Add 1 to the `value` in NIF and send the intermediate result to
  Elixir for further processing using the `callback` function.

  The result of the `callback` function is returned as the final result.

  ## Examples

      iex> Demo.add_one(1, fn result -> result * 2 end)
      4

  """
  def add_one(value, callback) do
    # remember to change the name of the Evaluator module if you have changed it
    # and pass both the evaluator and the callback function to the NIF
    evaluator = Process.whereis(Demo.Evaluator)
    Demo.NIF.add_one(value, evaluator, callback)
  end
end
```

After that, implement the `add_one` function in the NIF C code.

```c
static ERL_NIF_TERM add_one(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifSInt64 a;
  ErlNifPid evaluator;
  ERL_NIF_TERM fun = argv[2];

  if (!enif_get_int64(env, argv[0], &a) || !enif_get_local_pid(env, argv[1], &evaluator)) return enif_make_badarg(env);
  ERL_NIF_TERM result_term = enif_make_int64(env, a + 1);

  // send the intermediate result to Elixir for further processing
  // `make_nif_call` will return the result of the callback function
  // which is the final result in this case
  return make_nif_call(env, evaluator, fun, result_term);
}
```

Now, you can call the `add_one` function from Elixir.

```elixir
iex> Demo.add_one(1, fn result -> result * 2 end)
4
```

Congratulations! You have successfully called an Elixir function from NIF.
