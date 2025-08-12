import pog

pub type CustomError {
  FormError(String)
  PogError(pog.QueryError, String)
}

