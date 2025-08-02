import gleam/io
import youid/uuid
import app/schemas/items/sql
import gleam/dynamic/decode
import app/models/item.{type Item, create_item, status_to_bool}
import app/web.{type Context, Context}
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import wisp.{type Request, type Response}

type ItemsJson {
  ItemsJson(id: String, title: String, completed: Bool)
}

pub fn post_create_item(req: Request, ctx: Context) {
  use form <- wisp.require_form(req)

  let result = {
    use item_title <- result.try(list.key_find(form.values, "todo_title"))
    let new_item = create_item(item_title, item.Uncompleted)
    let status_bool = status_to_bool(new_item.status)
    sql.add_item(ctx.db, new_item.id, new_item.title, status_bool)
    |> result.replace_error(Nil)
  }
  case result {
    Ok(_) -> {
      wisp.redirect("/")
    }
    Error(error) -> {
      io.println("ERROR: " <> string.inspect(error))
      wisp.bad_request()
    }
  }
}

pub fn delete_item(req: Request, ctx: Context, item_id: String) {
  let current_items = ctx.items

  let json_items = {
    list.filter(current_items, fn(item) { uuid.to_string(item.id) != item_id })
    |> todos_to_json
  }
  wisp.redirect("/")
  |> wisp.set_cookie(req, "items", json_items, wisp.PlainText, 60 * 60 * 24)
}

pub fn patch_toggle_todo(req: Request, ctx: Context, item_id: String) {
  let current_items = ctx.items

  let result = {
    use _ <- result.try(
      list.find(current_items, fn(item) { uuid.to_string(item.id) == item_id }),
    )
    list.map(current_items, fn(item) {
      case uuid.to_string(item.id) == item_id {
        True -> item.toggle_todo(item)
        False -> item
      }
    })
    |> todos_to_json
    |> Ok
  }

  case result {
    Ok(json_items) ->
      wisp.redirect("/")
      |> wisp.set_cookie(req, "items", json_items, wisp.PlainText, 60 * 60 * 24)
    Error(_) -> wisp.bad_request()
  }
}

pub fn items_middleware(
  req: Request,
  ctx: Context,
  handle_request: fn(Context) -> Response,
) {
  let item_decoder = {
    use id <- decode.field("id", decode.string)
    use title <- decode.field("title", decode.string)
    use completed <- decode.field("completed", decode.bool)
    decode.success(ItemsJson(id:, title:, completed:))
  }
  let parsed_items = {
    case wisp.get_cookie(req, "items", wisp.PlainText) {
      Ok(json_string) -> {
        let result = json.parse(json_string, decode.list(of: item_decoder))
        case result {
          Ok(items) -> items
          Error(_) -> []
        }
      }
      Error(_) -> []
    }
  }

  let items = create_items_from_json(parsed_items)

  let ctx = Context(..ctx, items: items)

  handle_request(ctx)
}

fn create_items_from_json(items: List(ItemsJson)) -> List(Item) {
  items
  |> list.map(fn(item) {
    let ItemsJson(id, title, completed) = item
    item.item_from_json(id, title, completed)
  })
}

fn todos_to_json(items: List(Item)) -> String {
  "["
  <> items
  |> list.map(item_to_json)
  |> string.join(",")
  <> "]"
}

fn item_to_json(item: Item) -> String {
  json.object([
    #("id", json.string(uuid.to_string(item.id))),
    #("title", json.string(item.title)),
    #("completed", json.bool(status_to_bool(item.status))),
  ])
  |> json.to_string
}
