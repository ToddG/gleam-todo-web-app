import app/models/item.{type Item, create_item, status_to_bool}
import app/schemas/items/sql
import app/web.{type Context, Context}
import gleam/dynamic/decode
import gleam/io
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import pog.{Returned}
import wisp.{type Request, type Response}
import youid/uuid

type ItemsJson {
  ItemsJson(id: String, title: String, completed: Bool)
}

pub fn post_create_item(req: Request, ctx: Context) {
  use form <- wisp.require_form(req)

  let result = {
    use item_title <- result.try(list.key_find(form.values, "todo_title"))
    let new_item = create_item(item_title, item.Uncompleted)
    let status_bool = status_to_bool(new_item.status)
    // TODO: i want to bubble up the sql error, not squash it with Nil
    sql.add_item(ctx.db, new_item.id, new_item.title, status_bool)
    |> result.replace_error(Nil)
  }
  case result {
    Ok(_) -> {
      wisp.redirect("/")
    }
    Error(error) -> {
      // TODO: replace io.println with structured logging
      io.println_error(
        "item-routes-post-create-item : " <> string.inspect(error),
      )
      wisp.bad_request()
    }
  }
}

pub fn delete_item(_req: Request, ctx: Context, item_id: String) {
  case
    item_id
    |> uuid.from_string
    |> result.map(sql.delete_item(ctx.db, _))
  {
    Ok(_) -> wisp.redirect("/")
    Error(e) -> {
      io.println_error(
        "item-routes-delete-item-uuid-from-string : " <> string.inspect(e),
      )
      wisp.bad_request()
    }
  }
}

pub fn patch_toggle_todo(_req: Request, ctx: Context, item_id: String) {
  let current_item = {
    item_id
    |> uuid.from_string
    |> result.map(sql.find_item(ctx.db, _))
  }
  case current_item {
    Ok(Returned(count, rows)) -> {
      let result = {
        let x = list.first(rows)
        let f = item.toggle_todo(x)
        sql.update_item_status(ctx.db, f.id, item.status_to_bool(f.status))
      }
      case result {
        Ok(_) -> wisp.redirect("/")
        Error(e) -> {
          io.println_error("item-routes-patch-toggle-todo : update item failed : " <> string.inspect(e))
          wisp.bad_request()
        }
      }
    }
    Error(e) -> {
      io.println_error("item-routes-patch-toggle-todo : find item failed : " <> string.inspect(e))
      wisp.bad_request()
    }
  }
}



//  case
//    |> result.map(item.toggle_todo(_))
//    |> result.map(sql.update_item(ctx.db, _))
//  {
//    Error(e) ->{
//      io.println_error("item-routes-patch-toggle-todo : should only return 1 instance : " <> string.inspect(e))
//      wisp.bad_request()
//    }
//    Ok(x) -> {
//      io.println_error("item-routes-patch-toggle-todo : ok returned : " <> string.inspect(x))
//      wisp.redirect("/")
//      //      rows
//      //      |> list.first
//      //      |> item.item_from_row
//      //      |> item.toggle_todo
//      //      |> sql.update_item(ctx.db, _)
//    }
//  }
//}

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

//fn todos_to_json(items: List(Item)) -> String {
//  "["
//  <> items
//  |> list.map(item_to_json)
//  |> string.join(",")
//  <> "]"
//}
//
//fn item_to_json(item: Item) -> String {
//  json.object([
//    #("id", json.string(uuid.to_string(item.id))),
//    #("title", json.string(item.title)),
//    #("completed", json.bool(status_to_bool(item.status))),
//  ])
//  |> json.to_string
//}
