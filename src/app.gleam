import envoy
import gleam/result
import app/router
import app/web.{Context}
import dot_env
import dot_env/env
import gleam/erlang/process
import mist
import wisp
import wisp/wisp_mist

import cigogne
import cigogne/types

// BUGBUG: DEBUG ONLY
pub fn init_db() -> Result(Nil, types.MigrateError) {
   let assert Ok(db_url) = envoy.get("DATABASE_URL")
   let config = types.Config(
     ..cigogne.default_config,
     connection: types.UrlConfig(db_url)
   )
  use engine: cigogne.MigrationEngine <- result.try(cigogne.create_engine(config))
  cigogne.apply_to_last(engine)
}

pub fn main() {
  // BUGBUG: DEBUG ONLY
  let _db_result = init_db()
  wisp.configure_logger()

  dot_env.new()
  |> dot_env.set_path(".env")
  |> dot_env.set_debug(False)
  |> dot_env.load

  let assert Ok(secret_key_base) = env.get_string("SECRET_KEY_BASE")

  let ctx = Context(
    static_directory: static_directory(),
    items: []
  )

  let handler = router.handle_request(_, ctx)

  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start

  process.sleep_forever()
}

fn static_directory() -> String {
  let assert Ok(priv_directory) = wisp.priv_directory("app")
  priv_directory <> "/static"
}
