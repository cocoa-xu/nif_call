# nif_call

[![Hex.pm](https://img.shields.io/hexpm/v/nif_call.svg?style=flat&color=blue)](https://hex.pm/packages/nif_call)

Call Erlang/Elixir functions from NIF.

## Usage

### 1. Add `nif_call` as a dependency

Add `nif_call` as a dependency in your `mix.exs` file.

```elixir
defp deps do
  [
    {:nif_call, "~> 0.1"}
  ]
end
```

### 2. Get the header file

It's recommended to use the `nif_call`'s mix task to get the bundled header file. Assuming you're currently in the root directory of your project, run the following command:

```bash
mix nif_call.put_header
```

By default, the header file will be put in the `c_src` directory.  It may look like this:

```bash
.
├── Makefile
├── c_src
│   ├── demo_nif.cpp
│   └── nif_call.h          <-- From this repository
├── lib
│   └── demo
│       ├── application.ex
│       └── demo.ex
├── mix.exs
└── mix.lock
```

You can also change the directory by passing the `--dir` option.

```bash
mix nif_call.put_header --dir lib/nif_call
```

If there's already a `nif_call.h` file in the target directory, you may want to overwrite it by passing the `--overwrite` option.

```bash
mix nif_call.put_header --overwrite
```

### 3. Define Evaluator and NIF modules

Define an Evaluator module in your project. The Evaluator module is responsible for evaluating the Erlang/Elixir code. 

```elixir
# lib/demo/evaluator.ex
defmodule Demo.Evaluator do
  use NifCall.Evaluator
end
```

To send the evaluated result back to the caller, `nif_call` needs to inject one NIF function to do that.

```elixir
# lib/demo/nif.ex
defmodule Demo.NIF do
  use NifCall.NIF
end
```

The default name of this function is `nif_call_evaluated`. You can change it by passing the desired name to the `on_evaluated` option, like this:

```elixir
# lib/demo/evaluator.ex
defmodule Demo.Evaluator do
  use NifCall.Evaluator, on_evaluated: :my_evaluated
end
```

```elixir
# lib/demo/nif.ex
defmodule Demo.NIF do
  use NifCall.NIF, on_evaluated: :my_evaluated
end
```

### 4. Prepare C code

In your NIF code, include `nif_call.h` and define the `NIF_CALL_IMPLEMENTATION` macro before including it.

```c
// c_src/demo_nif.cpp
#define NIF_CALL_IMPLEMENTATION
#include "nif_call.h"
```

And remember to initialize nif_call in the `onload` function.

```c
// c_src/demo_nif.cpp
static int on_load(ErlNifEnv *env, void **, ERL_NIF_TERM) {
  // initialize nif_call
  return nif_call_onload(env);
}
```

Lastly, inject the NIF function:

```c
// c_src/demo_nif.cpp
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

### 5. Call Erlang/Elixir functions from NIF

Let's try to implement a simple function that adds 1 to the given value and sends the intermediate result to Elixir for further processing. The result of the Elixir callback function is returned as the final result.

First, we need to start the Evaluator process in the Elixir code.

```elixir
# lib/demo/application.ex
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
# lib/demo/demo.ex
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
// c_src/demo_nif.cpp
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

Most importantly, don't forget to add the NIF function to the `nif_functions` array, and **they have to be marked as dirty NIF functions**.

```c
// c_src/demo_nif.cpp
static ErlNifFunc nif_functions[] = {
  // ... your other NIF functions

  // inject nif_call functions
  NIF_CALL_NIF_FUNC(nif_call_evaluated),

  // add the NIF function
  // NIF functions that calls Elixir functions have to be marked as dirty
  // either ERL_NIF_DIRTY_JOB_CPU_BOUND or ERL_NIF_DIRTY_JOB_IO_BOUND
  {"add_one", 3, add_one, ERL_NIF_DIRTY_JOB_CPU_BOUND},
};
```

Now, you can call the `add_one` function from Elixir.

```elixir
iex> Demo.add_one(1, fn result -> result * 2 end)
4
```

Congratulations! You have successfully called an Elixir function from NIF.

There's a slightly more complex example in the `example` directory, which shows that you can make multiple calls to Elixir functions from NIF and 
use the intermediate results in the next call.
