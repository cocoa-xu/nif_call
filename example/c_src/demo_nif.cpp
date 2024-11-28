#include <erl_nif.h>
#include <string.h>

#define NIF_CALL_IMPLEMENTATION
#include "nif_call.h"

// ------ demo 1 start ------

static ERL_NIF_TERM add_one(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifSInt64 a;
  ErlNifPid evaluator;
  ERL_NIF_TERM fun = argv[2];

  if (!enif_get_int64(env, argv[0], &a) || !enif_get_local_pid(env, argv[1], &evaluator)) return enif_make_badarg(env);
  ERL_NIF_TERM result_term = enif_make_int64(env, a + 1);

  return make_nif_call(env, evaluator, fun, result_term);
}

// ------ demo 1 end ------

// ------ demo 2 start ------

static ERL_NIF_TERM kAtomCont;
static ERL_NIF_TERM kAtomDone;

static ERL_NIF_TERM iterate(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifSInt64 a;
  ErlNifPid evaluator;
  ERL_NIF_TERM iterate_val = argv[0];
  ERL_NIF_TERM fun = argv[2];

  if (!enif_get_local_pid(env, argv[1], &evaluator)) return enif_make_badarg(env);

  while (true) {
    if (!enif_get_int64(env, iterate_val, &a)) return enif_make_badarg(env);
    ERL_NIF_TERM val = enif_make_int64(env, a * 2);

    ERL_NIF_TERM callback_result = make_nif_call(env, evaluator, fun, val);
    const ERL_NIF_TERM *tuple_elements = NULL;
    int tuple_arity = 0;
    if (!enif_get_tuple(env, callback_result, &tuple_arity, &tuple_elements) || tuple_arity != 2) return enif_make_badarg(env);

    if (enif_compare(tuple_elements[0], kAtomCont) == 0) {
      iterate_val = tuple_elements[1];
    } else if (enif_compare(tuple_elements[0], kAtomDone) == 0) {
      return enif_make_copy(env, tuple_elements[1]);
    } else {
      return enif_make_badarg(env);
    }
  }
}

// ------ demo 2 end ------

static int on_load(ErlNifEnv *env, void **, ERL_NIF_TERM) {
  // constants for demo 2
  kAtomCont = enif_make_atom(env, "cont");
  kAtomDone = enif_make_atom(env, "done");

  // initialize nif_call
  return nif_call_onload(env);
}

static ErlNifFunc nif_functions[] = {
  // NIF functions that calls Elixir functions have to be marked as dirty
  // either ERL_NIF_DIRTY_JOB_CPU_BOUND or ERL_NIF_DIRTY_JOB_IO_BOUND
  {"add_one", 3, add_one, ERL_NIF_DIRTY_JOB_CPU_BOUND},
  {"iterate", 3, iterate, ERL_NIF_DIRTY_JOB_CPU_BOUND},

  // inject nif_call functions
  // `nif_call_evaluated` is the name of the callback function that will be called by nif_call
  NIF_CALL_NIF_FUNC(nif_call_evaluated),
};

ERL_NIF_INIT(Elixir.Demo.NIF, nif_functions, on_load, NULL, NULL, NULL);
