--- migration:up
CREATE TABLE items(
    id UUID PRIMARY KEY,
    title TEXT NOT NULL,
    status BOOL NOT NULL
);


--- migration:down
DROP TABLE items;

--- migration:end
