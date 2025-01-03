.PHONY: run
run:
	/home/toddg/.asdf/installs/rust/1.82.0/bin/watchexec \
		--restart --verbose --clear --wrap-process=session \
		--stop-signal SIGTERM --exts gleam --watch src/ -- "gleam run"

.PHONY: up
up:
	docker run --rm -P \
	    -p 127.0.0.1:5432:5432 \
	    -e POSTGRES_PASSWORD="1234" \
	    -e POSTGRES_USER="postgres" \
	    -e POSTGRES_DB="app" \
	    --name pg postgres:alpine

.PHONY: url
url:
	echo "DATABASE_URL=postgresql://postgres:1234@127.0.0.1:5432/app"

.PHONY: migrate
migrate:
    DATABASE_URL=postgresql://postgres:1234@127.0.0.1:5432/app gleam run -m cigogne up

.PHONY: down
down:
	docker stop pg
