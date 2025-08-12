import app/error
import app/models/item
import app/schemas/items/sql
import app/web.{type Context}
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import pog
import wisp.{type Request}
import youid/uuid

const todo_key: String = "todo_title"

pub fn create_item(req: Request, ctx: Context) -> wisp.Response {
  use form_data <- wisp.require_form(req)
  case
    form_data.values
    |> form_key_find
    |> result.map(item.create_item(_, item.Uncompleted))
    |> result.try(sql_add_item(ctx, _))
  {
    Ok(x) -> {
      io.println("create-item: item=" <> string.inspect(x))
      wisp.redirect("/")
    }
    Error(e) -> {
      io.println_error("create-item-failed-" <> string.inspect(e))
      wisp.bad_request()
    }
  }
}

pub fn delete_item(
  _req: Request,
  ctx: Context,
  item_id: String,
) -> wisp.Response {
  case
    item_id
    |> uuid.from_string
    |> result.map(sql_delete_item(ctx, _))
  {
    Ok(x) -> {
      io.println("delete-item: item=" <> string.inspect(x))
      wisp.redirect("/")
    }
    Error(e) -> {
      io.println_error("delete-item-failed-" <> string.inspect(e))
      wisp.bad_request()
    }
  }
}

pub fn patch_toggle_todo(
  _req: Request,
  ctx: Context,
  item_id: String,
) -> wisp.Response {
  case
    item_id
    |> uuid.from_string
    |> result.map_error(fn(_) {
      error.UuidError(
        "item-routes-patch-toggle-todo-uuid-from-string: item_id=" <> item_id,
      )
    })
    |> result.try(sql_find_item(ctx, _))
    |> result.try(toggle_item)
    |> result.try(sql_update_item_status(ctx, _))
  {
    Ok(_) -> {
      io.println("item-routes-patch-toggle-todo-succeeded: item_id=" <> item_id)
      wisp.redirect("/")
    }
    Error(e) -> {
      io.println_error(
        "item-routes-patch-toggle-todo-failed: item_id="
        <> item_id
        <> ", error="
        <> string.inspect(e),
      )
      wisp.bad_request()
    }
  }
}

//--------------------
//private functions

fn form_key_find(
  values: List(#(String, String)),
) -> Result(String, error.CustomError) {
  values
  |> list.key_find(todo_key)
  |> result.map_error(fn(_x) {
    error.FormError(
      "item-routes-post-create-item-key-find-failed: key=" <> todo_key,
    )
  })
}

fn sql_add_item(
  ctx: Context,
  x: item.Item,
) -> Result(item.Item, error.CustomError) {
  case
    sql.add_item(ctx.db, x.id, x.title, item.status_to_bool(x.status))
    |> result.map_error(fn(e) {
      error.DbError(
        e,
        "item-routes-add-item-failed: item=" <> string.inspect(x),
      )
    })
  {
    Ok(_) -> Ok(x)
    Error(e) -> Error(e)
  }
}

fn sql_find_item(
  ctx: Context,
  id: uuid.Uuid,
) -> Result(item.Item, error.CustomError) {
  case
    sql.find_item(ctx.db, id)
    |> result.map_error(fn(e) {
      error.DbError(
        e,
        "item-routes-find-item-failed: id=" <> string.inspect(id),
      )
    })
  {
    Ok(pog.Returned(1, [row])) -> {
      Ok(item.item_from_row(row))
    }
    Ok(pog.Returned(count:, rows: [_])) ->
      Error(error.DbError2(
        "item-routes-find-item-unknown-error: count=" <> string.inspect(count),
      ))
    Ok(pog.Returned(count:, rows: [_, _, ..])) ->
      Error(error.DbError2(
        "item-routes-find-item-too-many-results: count="
        <> string.inspect(count),
      ))
    Ok(pog.Returned(count:, rows: [])) ->
      Error(error.DbError2(
        "item-routes-find-item-zero-results: count=" <> string.inspect(count),
      ))
    Error(_) -> Error(error.DbError2("item-routes-find-item-catch-all-error"))
  }
}

fn toggle_item(x: item.Item) -> Result(item.Item, error.CustomError) {
  Ok(item.toggle_todo(x))
}

fn sql_update_item_status(
  ctx: Context,
  x: item.Item,
) -> Result(item.Item, error.CustomError) {
  case
    sql.update_item_status(ctx.db, x.id, item.status_to_bool(x.status))
    |> result.map_error(fn(e) {
      error.DbError(
        e,
        "item-routes-update-item-status-failed: item=" <> string.inspect(x),
      )
    })
  {
    Ok(_) -> Ok(x)
    Error(_) ->
      Error(error.DbError2("item-routes-upgrade-item-status-catch-all-error"))
  }
}

fn sql_delete_item(
  ctx: Context,
  item_id: uuid.Uuid,
) -> Result(uuid.Uuid, error.CustomError) {
  case
    sql.delete_item(ctx.db, item_id)
    |> result.map_error(fn(e) {
      error.DbError(
        e,
        "item-routes-delete-item-failed: item_id="
          <> string.inspect(item_id)
          <> ", error="
          <> string.inspect(e),
      )
    })
  {
    Ok(_) -> Ok(item_id)
    Error(e) -> Error(e)
  }
}
