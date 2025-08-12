import app/schemas/items/sql
import youid/uuid

pub type ItemStatus {
  Completed
  Uncompleted
}

pub type Item {
  Item(id: uuid.Uuid, title: String, status: ItemStatus)
}

pub fn create_item(title: String, status: ItemStatus) -> Item {
  Item(id: uuid.v4(), title: title, status: status)
}

pub fn item_from_row(row: sql.FindItemRow) -> Item {
  Item(
    id: row.id,
    title: row.title,
    status: bool_to_status(row.status),
  )
}

pub fn items_from_rows(row: sql.ListItemsRow) -> Item {
  Item(
  id: row.id,
  title: row.title,
  status: bool_to_status(row.status),
  )
}

pub fn toggle_todo(item: Item) -> Item {
  let new_status = case item.status {
    Completed -> Uncompleted
    Uncompleted -> Completed
  }
  Item(..item, status: new_status)
}

pub fn status_to_bool(status: ItemStatus) -> Bool {
  case status {
    Completed -> True
    Uncompleted -> False
  }
}

fn bool_to_status(status: Bool) -> ItemStatus {
  case status {
    True -> Completed
    False -> Uncompleted
  }
}