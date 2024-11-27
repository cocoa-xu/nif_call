#include <erl_nif.h>
#include <string.h>

// ------- Library code start -------

struct CallbackNifRes {
  static ErlNifResourceType *type;
  ErlNifPid process;
  ErlNifEnv * msg_env;
  ErlNifMutex *mtx = NULL;
  ErlNifCond *cond = NULL;
  ERL_NIF_TERM return_value;
};

ErlNifResourceType * CallbackNifRes::type = NULL;

static CallbackNifRes * prepare_nif_callback(ErlNifEnv* env) {
  CallbackNifRes *res = (CallbackNifRes *)enif_alloc_resource(CallbackNifRes::type, sizeof(CallbackNifRes));
  if (!res) return NULL;
  memset(res, 0, sizeof(CallbackNifRes));
  
  enif_self(env, &res->process);
  res->msg_env = env;
  // ErlNifEnv * msg_env = enif_alloc_env();
  // if (!msg_env) {
  //   enif_mutex_destroy(mtx);
  //   enif_cond_destroy(cond);
  //   return enif_make_atom(env, "error");
  // }

  res->mtx = enif_mutex_create((char *)"nif_call_mutex");
  if (!res->mtx) {
    enif_release_resource(res);
    return NULL;
  }

  res->cond = enif_cond_create((char *)"nif_call_cond");
  if (!res->cond) {
    enif_mutex_destroy(res->mtx);
    enif_release_resource(res);
    return NULL;
  }

  // default return value
  res->return_value = enif_make_atom(env, "nil");

  return res;
}

static ERL_NIF_TERM make_elixir_call(ErlNifEnv* env, ERL_NIF_TERM mf, ERL_NIF_TERM args) {
  CallbackNifRes *callback_res = prepare_nif_callback(env);
  ERL_NIF_TERM callback_term = enif_make_resource(env, (void *)callback_res);

  enif_send(env, &callback_res->process, NULL, enif_make_tuple3(env,
    mf,
    args,
    callback_term
  ));

  enif_cond_wait(callback_res->cond, callback_res->mtx);
  return callback_res->return_value;
}

static ERL_NIF_TERM evaluated(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  CallbackNifRes *res = NULL;
  if (!enif_get_resource(env, argv[0], CallbackNifRes::type, (void **)&res)) return enif_make_badarg(env);

  res->return_value = enif_make_copy(res->msg_env, argv[1]);
  enif_cond_signal(res->cond);

  return enif_make_atom(env, "ok");
}

static void destruct_nif_callback(ErlNifEnv *, void *obj) {
  CallbackNifRes *res = (CallbackNifRes *)obj;
  enif_cond_destroy(res->cond);
  // enif_free_env(res->msg_env);
}

// ------- Library code end -------

// ------- User code start -------

static ERL_NIF_TERM compute(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifSInt64 a, b;
  ERL_NIF_TERM fun_or_mfa = argv[2];

  if (!enif_get_int64(env, argv[0], &a) || !enif_get_int64(env, argv[1], &b)) return enif_make_badarg(env);
  ERL_NIF_TERM result_term = enif_make_int64(env, a + b);

  return make_elixir_call(env, fun_or_mfa, result_term);
}

// ------- User code end -------

static int on_load(ErlNifEnv *env, void **, ERL_NIF_TERM) {
  ErlNifResourceType *rt;

  {
    rt = enif_open_resource_type(env, "Elixir.NifCall.NIF", "CallbackNifRes", destruct_nif_callback, ERL_NIF_RT_CREATE, NULL);
    if (!rt) return -1;
    CallbackNifRes::type = rt;
  }

  return 0;
}

static ErlNifFunc nif_functions[] = {
  {"compute", 3, compute, ERL_NIF_DIRTY_JOB_CPU_BOUND},
  {"evaluated", 2, evaluated, 0}
};

ERL_NIF_INIT(Elixir.Foo.NIF, nif_functions, on_load, NULL, NULL, NULL);
