import app/router
import app/web.{Context}
import dot_env
import dot_env/env
import envoy
import gleam/erlang/process
import gleam/otp/static_supervisor as supervisor
import gleam/result
import mist
import pog
import wisp
import wisp/wisp_mist

import cigogne
import cigogne/types

pub fn migrate_db() -> Result(Nil, types.MigrateError) {
  // TODO: migrate_db should take the db connection from read_connection_uri below
  let assert Ok(db_url) = envoy.get("DATABASE_URL")
  let config =
    types.Config(..cigogne.default_config, connection: types.UrlConfig(db_url))
  use engine: cigogne.MigrationEngine <- result.try(cigogne.create_engine(
    config,
  ))
  cigogne.apply_to_last(engine)
}

pub fn read_connection_uri(
  name: process.Name(pog.Message),
) -> Result(pog.Config, Nil) {
  use database_url <- result.try(envoy.get("DATABASE_URL"))
  pog.url_config(name, database_url)
}

pub fn start_application_supervisor(db_pool_name: process.Name(pog.Message)) {
  let assert Ok(config) = read_connection_uri(db_pool_name)
  let db_pool_child = {
    config
    |> pog.pool_size(15)
    |> pog.supervised
  }

  supervisor.new(supervisor.RestForOne)
  |> supervisor.add(db_pool_child)
  // |> supervisor.add(other)
  // |> supervisor.add(application)
  // |> supervisor.add(children)
  |> supervisor.start
}

fn static_directory() -> String {
  let assert Ok(priv_directory) = wisp.priv_directory("app")
  priv_directory <> "/static"
}

pub fn main() {
  wisp.configure_logger()

  let db_pool_name = process.new_name("db_pool")
  let _db_migration_result = migrate_db()
  let _ = start_application_supervisor(db_pool_name)
  let db_connection_pool = pog.named_connection(db_pool_name)

  wisp.configure_logger()

  // TODO: replace all dot_env calls with envoy so that we follow 12 factor
  dot_env.new()
  |> dot_env.set_path(".env")
  |> dot_env.set_debug(False)
  |> dot_env.load

  let assert Ok(secret_key_base) = env.get_string("SECRET_KEY_BASE")

  let ctx =
    Context(
      static_directory: static_directory(),
      items: [],
      db: db_connection_pool,
    )

  let handler = router.handle_request(_, ctx)

  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start

  process.sleep_forever()
}
