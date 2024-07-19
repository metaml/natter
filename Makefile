.DEFAULT_GOAL = help

run: ## run nat, rest server
	uvicorn app.chat:chat

run-dev: ## run nat, rest server in dev mode
	uvicorn app.app:chat --reload

build: ## build python package
	nix build

image: ## docker image
	nix build --impure --verbose --option sandbox relaxed .#docker

clean: ## clean
	find . -name \*~ | xargs rm -f

update: ## install/update python packages
	pip install -r requirements.txt

dev: ## nix develop
	nix develop

help: ## help
	-@grep --extended-regexp '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sed 's/^Makefile://1' \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}'

