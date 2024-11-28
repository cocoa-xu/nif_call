#include <erl_nif.h>
#include <string.h>

#define NIF_CALL_IMPLEMENTATION
#include "nif_call.h"

static ERL_NIF_TERM compute(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifSInt64 a;
  ErlNifPid evaluator;
  ERL_NIF_TERM fun = argv[2];

  if (!enif_get_int64(env, argv[0], &a) || !enif_get_local_pid(env, argv[1], &evaluator)) return enif_make_badarg(env);
  ERL_NIF_TERM result_term = enif_make_int64(env, a + 1);

  return make_nif_call(env, evaluator, fun, result_term);
}

static int on_load(ErlNifEnv *env, void **, ERL_NIF_TERM) {
  ErlNifResourceType *rt;

  {
    rt = enif_open_resource_type(env, "Elixir.Foo.NIF", "CallbackNifRes", destruct_nif_call_res, ERL_NIF_RT_CREATE, NULL);
    if (!rt) return -1;
    CallbackNifRes::type = rt;

    CallbackNifRes::kAtomNil = enif_make_atom(env, "nil");
    CallbackNifRes::kAtomENOMEM = enif_make_atom(env, "enomem");
  }

  return 0;
}

static ErlNifFunc nif_functions[] = {
  {"compute", 3, compute, ERL_NIF_DIRTY_JOB_CPU_BOUND},
  {"nif_call_evaluated", 2, nif_call_evaluated, 0}
};

ERL_NIF_INIT(Elixir.Foo.NIF, nif_functions, on_load, NULL, NULL, NULL);
