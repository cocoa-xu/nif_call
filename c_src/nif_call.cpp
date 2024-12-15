#include <erl_nif.h>
#include <string.h>

#define NIF_CALL_IMPLEMENTATION
#include "nif_call.h"

static int on_load(ErlNifEnv *env, void **, ERL_NIF_TERM) {
  return nif_call_onload(env);
}

static ErlNifFunc nif_functions[] = {
  NIF_CALL_NIF_FUNC(nif_call_evaluated),
};

ERL_NIF_INIT(Elixir.NifCall.NIF, nif_functions, on_load, NULL, NULL, NULL);
