import gleam/string
import pog

pub type CustomError {
  FormError(String)
  DbError(pog.QueryError, String)
  DbError2(String)
  UuidError(String)
  Nil
}

pub fn custom_error_to_string(e: CustomError) -> String {
  case e {
    DbError2(m) -> "DbError2(msg=" <> m <> ")"
    DbError(e, m) -> "DbError(error=" <> string.inspect(e) <> ", msg=" <> m <> ")"
    FormError(m) -> "FormError(msg=" <> m <> ")"
    UuidError(m) -> "UuidError(msg=" <> m <> ")"
    Nil -> "nil"
  }
}