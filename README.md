# Code for article "Building your first Gleam web app with Wisp and Lustre"

## dependencies

* postgresql-client
* make
* gleam
* brew
* watchexec

### install deps

#### linux

```bash
sudo apt-get install postgresql-client make
brew install gleam
brew install watchexec
```

## quickstart

### terminal 1

Launch the postgresql database:

```
make dbup
```

### terminal 2

Launch the server:

```
make run
```

### terminal 3

Watch what's happening in the database:

```
make psql
```

### in browser

navigate to http://localhost/8000

## background

Read the article on Gleaming: [https://gleaming.dev/articles/building-your-first-gleam-web-app](https://gleaming.dev/articles/building-your-first-gleam-web-app)

## warts and all that (architecture)

### separation of models and schemas

you'll notice that there is a strong separation between the database schemas `/app/schemas` and the models `/app/models`.
this is on purpose. in short, the models are a higher level of abstraction than the schemas. the schemas are