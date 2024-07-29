.DEFAULT_GOAL = help

ACCOUNT_ID := 975050288432
# aws and openai dependency conflict with urllib3
AWS := PYTHONPATH= aws

run: export OPENAI_API_KEY=$(shell $(AWS) secretsmanager get-secret-value --secret-id=openai-api-key --output json | jq --raw-output '.SecretString' | jq --raw-output '."openai-api-key"')
run: ## run aip, rest server
	echo "KEY=$(OPENAI_API_KEY)"
	uvicorn aip:aip

run-dev: ## run aip, rest server in dev mode
	uvicorn aip:aip --reload

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
	nix develop --show-trace

help: ## help
	-@grep --extended-regexp '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sed 's/^Makefile://1' \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}'


login-aws: ## login to aws to fetch/refresh token
	PYTHONPATH= $(AWS) sso login # AdministratorAccess-975050288432

# useful utlities below

image-push: REGION = us-east-2
image-push: DOCKER_LOGIN = $(shell $(AWS) ecr get-login-password --region $(REGION))
image-push: image-load ## push image to ecr
	docker tag aip:latest $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/aip:latest
	$(AWS) ecr get-login-password --region $(REGION) \
	| docker login --username AWS --password-stdin $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com
	docker push $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/aip:latest

image-load: ## load docker image
	docker load < result

image-run: image-load ## run the image
	docker run --platform linux/am64 --interactive --tty --rm aip

image-clean: ## remove images
	docker system prune -a --volumes

api-test: ## test openai api 
	curl https://api.openai.com/v1/chat/completions \
	--header "Content-Type: application/json" \
	--header "Authorization: Bearer ${OPENAI_API_KEY}" \
	--data @"./etc/api-test.json"

# $ tar cvf aip.tar --exclude='.git/*' --exclude='venv' aip
# $ scp aip.tar ec2-18-219-30-120.us-east-2.compute.amazonaws.com:/tmp
# $ ssh -L 8000:localhost:8000 ec2-18-219-30-120.us-east-2.compute.amazonaws.com
#
.PHONY: venv
