.PHONY: run

run:
	/home/toddg/.asdf/installs/rust/1.82.0/bin/watchexec --restart --verbose --clear --wrap-process=session --stop-signal SIGTERM --exts gleam --watch src/ -- "gleam run"
