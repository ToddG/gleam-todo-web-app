import gleam/dynamic/decode
import pog
import youid/uuid.{type Uuid}

/// Runs the `delete_item` query
/// defined in `./src/items/sql/delete_item.sql`.
///
/// > 🐿️ This function was generated automatically using v2.1.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_item(db, arg_1) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  let query = "delete from items where id = $1;"

  pog.query(query)
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `add_item` query
/// defined in `./src/items/sql/add_item.sql`.
///
/// > 🐿️ This function was generated automatically using v2.1.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn add_item(db, arg_1, arg_2, arg_3) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  let query = "insert into items (id, title, status) values ($1, $2, $3);"

  pog.query(query)
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.bool(arg_3))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_items` query
/// defined in `./src/items/sql/list_items.sql`.
///
/// > 🐿️ This type definition was generated automatically using v2.1.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListItemsRow {
  ListItemsRow(id: Uuid, title: String, status: Bool)
}

/// Runs the `list_items` query
/// defined in `./src/items/sql/list_items.sql`.
///
/// > 🐿️ This function was generated automatically using v2.1.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_items(db) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use title <- decode.field(1, decode.string)
    use status <- decode.field(2, decode.bool)
    decode.success(ListItemsRow(id:, title:, status:))
  }

  let query = "select id, title, status from items;"

  pog.query(query)
  |> pog.returning(decoder)
  |> pog.execute(db)
}

// --- Encoding/decoding utils -------------------------------------------------

/// A decoder to decode `Uuid`s coming from a Postgres query.
///
fn uuid_decoder() {
  use bit_array <- decode.then(decode.bit_array)
  case uuid.from_bit_array(bit_array) {
    Ok(uuid) -> decode.success(uuid)
    Error(_) -> decode.failure(uuid.v7(), "uuid")
  }
}
