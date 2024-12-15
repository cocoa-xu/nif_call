#include <erl_nif.h>
#include <string.h>

#define NIF_CALL_NAMESPACE demo
#define NIF_CALL_IMPLEMENTATION
#include "nif_call.h"

// ------ demo 1 start ------

static ERL_NIF_TERM add_one(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifSInt64 a;
  ERL_NIF_TERM tag = argv[1];

  if (!enif_get_int64(env, argv[0], &a)) return enif_make_badarg(env);
  ERL_NIF_TERM result_term = enif_make_int64(env, a + 1);

  NifCallResult result = make_nif_call(env, tag, result_term);
  return result.is_ok() ? result.get_value() : enif_make_tuple2(env, result.get_kind(), result.get_err());
}

// ------ demo 1 end ------

// ------ demo 2 start ------

static ERL_NIF_TERM kAtomCont;
static ERL_NIF_TERM kAtomDone;

static ERL_NIF_TERM iterate(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifSInt64 a;
  ERL_NIF_TERM iterate_val = argv[0];
  ERL_NIF_TERM tag = argv[1];

  while (true) {
    if (!enif_get_int64(env, iterate_val, &a)) return enif_make_badarg(env);
    ERL_NIF_TERM val = enif_make_int64(env, a * 2);

    NifCallResult result = make_nif_call(env, tag, val);
    if (!result.is_ok()) return enif_make_tuple2(env, result.get_kind(), result.get_err());

    ERL_NIF_TERM callback_result = result.get_value();
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
  {"add_one", 2, add_one, ERL_NIF_DIRTY_JOB_CPU_BOUND},
  {"iterate", 2, iterate, ERL_NIF_DIRTY_JOB_CPU_BOUND},

  // inject nif_call functions
  // `nif_call_evaluated` is the name of the callback function that will be called by nif_call
  NIF_CALL_NIF_FUNC(nif_call_evaluated),
};

ERL_NIF_INIT(Elixir.Demo.NIF, nif_functions, on_load, NULL, NULL, NULL);
