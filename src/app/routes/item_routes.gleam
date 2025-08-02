import gleam/int
import pog
import app/models/item.{create_item, status_to_bool}
import app/schemas/items/sql
import app/web.{type Context, Context}
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import wisp.{type Request}
import youid/uuid

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
  case uuid.from_string(item_id)
  {
    Ok(u) -> {
      case sql.find_item(ctx.db, u) {
        Ok(pog.Returned(1, [row])) -> {
          let original_item = item.item_from_row(row)
          let toggled_item = item.toggle_todo(original_item)
          let _ = sql.update_item_status(ctx.db, toggled_item.id, item.status_to_bool(toggled_item.status))
          wisp.redirect("/")
        }
        Error(e) -> {
          io.println_error("item-routes-patch-toggle-todo : uuid from string failed : " <> string.inspect(e))
          wisp.bad_request()
        }
        Ok(pog.Returned(count, _)) -> {
          io.println_error("item-routes-patch-toggle-todo : unexpected count, expected only 1 found : " <> int.to_string(count))
          wisp.bad_request()
        }
      }
      wisp.redirect("/")
    }
    Error(e) -> {
      io.println_error("item-routes-patch-toggle-todo : uuid from string failed : " <> string.inspect(e))
      wisp.bad_request()
    }
  }
}
