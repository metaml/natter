run: ## run nat, rest server
	uvicorn main:app

run-dev: ## run nat, rest server in dev mode
	uvicorn main:app --reload

run-chat: ## run chat
	./app/natdev.py

clean: ## clean
	find . -name \*~ | xargs rm -f

update: ## update/install pypi packages
	pip install -r requirements.txt

dev: ## nix develop
	nix develop

help: ## help
	-@grep --extended-regexp '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sed 's/^Makefile://1' \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}'

.PHONY: poetry.lock
