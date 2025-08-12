import pog

pub type CustomError {
  FormError(String)
  DbError(pog.QueryError, String)
  DbError2(String)
  UuidError(String)
}
