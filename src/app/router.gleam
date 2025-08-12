import app/models/item
import app/pages
import app/pages/layout.{layout}
import app/routes/item_routes
import app/schemas/items/sql
import app/web.{type Context}
import gleam/http
import gleam/io
import gleam/list
import gleam/string
import lustre/element
import pog
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req, ctx)
  //  use ctx <- items_middleware(req, ctx)

  case wisp.path_segments(req) {
    // Homepage
    [] -> {
      case sql.list_items(ctx.db) {
        Ok(pog.Returned(_count, rows)) -> {
          [pages.home(list.map(rows, item.items_from_rows))]
          |> layout
          |> element.to_document_string_tree
          |> wisp.html_response(200)
        }
        Error(e) -> {
          io.println_error(string.inspect(e))
          wisp.bad_request()
        }
      }
    }

    ["items", "create"] -> {
      use <- wisp.require_method(req, http.Post)
      item_routes.create_item(req, ctx)
    }

    ["items", id] -> {
      use <- wisp.require_method(req, http.Delete)
      item_routes.delete_item(req, ctx, id)
    }

    ["items", id, "completion"] -> {
      use <- wisp.require_method(req, http.Patch)
      item_routes.toggle_todo(req, ctx, id)
    }
    // All the empty responses
    ["internal-server-error"] -> wisp.internal_server_error()
    ["unprocessable-entity"] -> wisp.unprocessable_entity()
    ["method-not-allowed"] -> wisp.method_not_allowed([])
    ["entity-too-large"] -> wisp.entity_too_large()
    ["bad-request"] -> wisp.bad_request()
    _ -> wisp.not_found()
  }
}
