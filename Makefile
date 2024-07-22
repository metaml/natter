.DEFAULT_GOAL = help

ACCOUNT_ID := 975050288432

run: ## run aip, rest server
	uvicorn app.aip:app

run-dev: ## run aip, rest server in dev mode
	uvicorn app.aip:app --reload

build: ## build python package
	nix build

image: ## docker image
	nix build --impure --verbose --option sandbox relaxed .#docker

push: image image-push ## push docker image to ecr

clean: ## clean
	find . -name \*~ | xargs rm -f

clobber: clean ## clobber dev env
	rm -rf venv/*

update: ## install/update python packages
	pip install -r requirements.txt

dev: ## nix develop
	nix develop

help: ## help
	-@grep --extended-regexp '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sed 's/^Makefile://1' \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}'

# useful utlities below

image-push: REGION = us-east-2
image-push: DOCKER_LOGIN = $(shell aws ecr get-login-password --region $(REGION))
image-push: image-load ## push image to ecr
	docker tag aip:latest $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/aip:latest
	aws ecr get-login-password --region $(REGION) \
	| docker login --username AWS --password-stdin $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com
	docker push $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/aip:latest

image-load: ## load docker image
	docker load < result

image-run: image-load ## run the image
	docker run --platform linux/am64 --interactive --tty --rm aip

image-clean: ## remove images
	docker system prune -a --volumes
