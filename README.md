# Code for article "Building your first Gleam web app with Wisp and Lustre"

## dependencies

### linux

```bash
sudo apt-get install postgresql-client
```
* make
* gleam

## quickstart

### terminal 1

Launch the postgresql database:
```make up```

### terminal 2

Run the server:
```make run```

### terminal 3

Run the db migrations to create the items schema:

```DATABASE_URL=postgresql://postgres:1234@127.0.0.1:5432/app gleam run -m cigogne apply 1 ```



Read the article on Gleaming: [https://gleaming.dev/articles/building-your-first-gleam-web-app](https://gleaming.dev/articles/building-your-first-gleam-web-app)