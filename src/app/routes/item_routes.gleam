import app/error
import app/models/item
import app/schemas/items/sql
import app/web.{type Context}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import pog
import wisp.{type Request}
import youid/uuid

const todo_key: String = "todo_title"

pub fn post_create_item(req: Request, ctx: Context) -> wisp.Response {
  use form_data <- wisp.require_form(req)

  case list.key_find(form_data.values, todo_key) {
    Ok(v) -> {
      let x = item.create_item(v, item.Uncompleted)
      let r = sql.add_item(ctx.db, x.id, x.title, item.status_to_bool(x.status))
      case r {
        Ok(_) -> {
          io.println("created: " <> string.inspect(x))
          wisp.redirect("/")
        }
        Error(e) -> {
          io.println_error(
            "error creating item: "
            <> string.inspect(x)
            <> ", error: "
            <> string.inspect(e),
          )
          wisp.bad_request()
        }
      }
    }
    Error(e) -> {
      io.println_error("foo: " <> string.inspect(e))
      wisp.bad_request()
    }
  }
}

pub fn post_create_item2(req: Request, ctx: Context) -> wisp.Response {
  use form_data <- wisp.require_form(req)

  let fn_add_item = {
    fn(x: item.Item) -> Result(pog.Returned(Nil), error.CustomError) {
      sql.add_item(ctx.db, x.id, x.title, item.status_to_bool(x.status))
      |> result.map_error(fn(e) { error.PogError(e, "item-routes-post-create-add-item-failed: item=" <> string.inspect(x)) })
    }
  }

  case
    form_data.values
    |> list.key_find(todo_key)
    |> result.map_error(fn(_x) {
      error.FormError("item-routes-post-create-find-key-failed: key=" <> todo_key)
    })
    |> result.map(item.create_item(_, item.Uncompleted))
    |> result.try(fn_add_item)
  {
    Ok(_) -> {
      wisp.redirect("/")
    }
    Error(e) -> {
      io.println_error(string.inspect(e))
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
  case uuid.from_string(item_id) {
    Ok(u) -> {
      case sql.find_item(ctx.db, u) {
        Ok(pog.Returned(1, [row])) -> {
          let original_item = item.item_from_row(row)
          let toggled_item = item.toggle_todo(original_item)
          let _ =
            sql.update_item_status(
              ctx.db,
              toggled_item.id,
              item.status_to_bool(toggled_item.status),
            )
          wisp.redirect("/")
        }
        Error(e) -> {
          io.println_error(
            "item-routes-patch-toggle-todo : uuid from string failed : "
            <> string.inspect(e),
          )
          wisp.bad_request()
        }
        Ok(pog.Returned(count, _)) -> {
          io.println_error(
            "item-routes-patch-toggle-todo : unexpected count, expected only 1 found : "
            <> int.to_string(count),
          )
          wisp.bad_request()
        }
      }
      wisp.redirect("/")
    }
    Error(e) -> {
      io.println_error(
        "item-routes-patch-toggle-todo : uuid from string failed : "
        <> string.inspect(e),
      )
      wisp.bad_request()
    }
  }
}
