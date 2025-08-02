.PHONY: help
help:	## print help message
	@grep -Eh '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m  %-30s\033[0m %s\n", $$1, $$2}'


.PHONY: run
run: 	## run service and restart on code changes
	watchexec \
		--restart --verbose --clear --wrap-process=session \
		--stop-signal SIGTERM --exts gleam --watch src/ -- "DATABASE_URL=postgresql://postgres:1234@127.0.0.1:5432/app gleam run"

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
url:	## print the database url so you can connect to the db with other tools
	echo "DATABASE_URL=postgresql://postgres:1234@127.0.0.1:5432/app"

# BUGBUG: this doesn't work for some weird reason, the DATABASE_URL isn't getting
# BUGBUG: picked up by the cigogne command. but it works fine when run from the
# BUGBUG: command line. disabling for now and running the migrate as part of app startup
#
#.PHONY: migrate
#migrate: 
#	DATABASE_URL=postgresql://postgres:1234@127.0.0.1:5432/app gleam run -m cigogne up

.PHONY: squirrel
squirrel: ## generate schema bindings
	DATABASE_URL=postgresql://postgres:1234@127.0.0.1:5432/app gleam run -m squirrel
