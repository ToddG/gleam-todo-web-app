import app/error
import app/models/item
import app/schemas/items/sql
import app/web.{type Context}
import gleam/list
import gleam/result
import gleam/string
import logging.{Info, Warning}
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
      logging.log(Info, "create-item-succeeded: item=" <> string.inspect(x))
      wisp.redirect("/")
    }
    Error(e) -> {
      logging.log(Warning, "create-item-failed" <> string.inspect(e))
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
      logging.log(Info, "delete-item-succeeded: item=" <> string.inspect(x))
      wisp.redirect("/")
    }
    Error(e) -> {
      logging.log(Warning, "delete-item-failed-" <> string.inspect(e))
      wisp.bad_request()
    }
  }
}

pub fn toggle_todo(
  _req: Request,
  ctx: Context,
  item_id: String,
) -> wisp.Response {
  case
    item_id
    |> uuid.from_string
    |> result.map_error(fn(_) {
      error.UuidError("uuid-from-string-failed: item_id=" <> item_id)
    })
    |> result.try(sql_find_item(ctx, _))
    |> result.try(toggle_item)
    |> result.try(sql_update_item_status(ctx, _))
  {
    Ok(_) -> {
      logging.log(Info, "toggle-todo-succeeded: item_id=" <> item_id)
      wisp.redirect("/")
    }
    Error(e) -> {
      logging.log(Warning, "toggle-todo-failed-" <> string.inspect(e))
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
    error.FormError("form-key-find-failed: key=" <> todo_key)
  })
}

fn sql_add_item(
  ctx: Context,
  x: item.Item,
) -> Result(item.Item, error.CustomError) {
  case sql.add_item(ctx.db, x.id, x.title, item.status_to_bool(x.status)) {
    Ok(_) -> Ok(x)
    Error(e) ->
      Error(error.DbError(e, "sql-add-item-failed: item=" <> string.inspect(x)))
  }
}

fn sql_find_item(
  ctx: Context,
  id: uuid.Uuid,
) -> Result(item.Item, error.CustomError) {
  case sql.find_item(ctx.db, id) {
    Ok(pog.Returned(1, [row])) -> {
      Ok(item.item_from_row(row))
    }
    Ok(pog.Returned(count:, rows: [_])) ->
      Error(error.DbError2(
        "sql-find-item-unknown-error: count=" <> string.inspect(count),
      ))
    Ok(pog.Returned(count:, rows: [_, _, ..])) ->
      Error(error.DbError2(
        "sql-find-item-too-many-results: count=" <> string.inspect(count),
      ))
    Ok(pog.Returned(count:, rows: [])) ->
      Error(error.DbError2(
        "sql-find-item-zero-results: count=" <> string.inspect(count),
      ))
    Error(e) ->
      Error(error.DbError(e, "sql-find-item-failed: id=" <> uuid.to_string(id)))
  }
}

fn toggle_item(x: item.Item) -> Result(item.Item, error.CustomError) {
  Ok(item.toggle_todo(x))
}

fn sql_update_item_status(
  ctx: Context,
  x: item.Item,
) -> Result(item.Item, error.CustomError) {
  case sql.update_item_status(ctx.db, x.id, item.status_to_bool(x.status)) {
    Ok(_) -> Ok(x)
    Error(e) ->
      Error(error.DbError(
        e,
        "sql-update-item-status-failed: item=" <> string.inspect(x),
      ))
  }
}

fn sql_delete_item(
  ctx: Context,
  item_id: uuid.Uuid,
) -> Result(uuid.Uuid, error.CustomError) {
  case sql.delete_item(ctx.db, item_id) {
    Ok(_) -> Ok(item_id)
    Error(e) ->
      Error(error.DbError(
        e,
        "sql-delete-item-failed: item_id=" <> uuid.to_string(item_id),
      ))
  }
}
