.PHONY: help
help:	## print help message
	@grep -Eh '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m  %-30s\033[0m %s\n", $$1, $$2}'


.PHONY: run
run: 	## run service
	/home/toddg/.asdf/installs/rust/1.82.0/bin/watchexec \
		--restart --verbose --clear --wrap-process=session \
		--stop-signal SIGTERM --exts gleam --watch src/ -- "gleam run"

.PHONY: up
up:	## start postgress
	docker run --rm -P \
	    -p 127.0.0.1:5432:5432 \
	    -e POSTGRES_PASSWORD="1234" \
	    -e POSTGRES_USER="postgres" \
	    -e POSTGRES_DB="app" \
	    --name pg postgres:alpine

.PHONY: down
down:	## stop postgres
	docker stop pg

.PHONY: url
url:	## print the database url
	echo "DATABASE_URL=postgresql://postgres:1234@127.0.0.1:5432/app"

.PHONY: migrate
migrate: ## migrate the database
	DATABASE_URL=postgresql://postgres:1234@127.0.0.1:5432/app gleam run -m cigogne up

.PHONY: squirrel
squirrel: ## generate schema bindings
	DATABASE_URL=postgresql://postgres:1234@127.0.0.1:5432/app gleam run -m squirrel
