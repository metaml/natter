.DEFAULT_GOAL = help

ACCOUNT_ID := 975050288432
AWS := PYTHONPATH= aws # aws and openai dependency conflict with urllib3

run: ## run aip, rest server
	./app/aip.py

run-dev: export AIP_DEVELOPMENT=1 # can be any non-null value
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
	docker tag aip:latest $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/aip-lambda:latest
	$(AWS) ecr get-login-password --region $(REGION) \
	| docker login --username AWS --password-stdin $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com
	docker push $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/aip-lambda:latest

image-load: ## load docker image
	docker load < result

image-run: image-load ## run the image
	docker run --platform linux/am64 --interactive --tty --rm aip

image-clean: ## remove images
	docker system prune -a --volumes

api-test: OPENAI_API_KEY = $(shell $(AWS) secretsmanager get-secret-value --secret-id=openai-api-key --output json | jq --raw-output '.SecretString')
api-test: ## test openai api 
	curl https://api.openai.com/v1/chat/completions \
	--header "Content-Type: application/json" \
	--header "Authorization: Bearer ${OPENAI_API_KEY}" \
	--data @"./etc/api-test.json"

sns-test: export PYTHONPATH=#
sns-test: ## test sns
	aws sns publish \
	--topic-arn arn:aws:sns:us-east-2:975050288432:aip \
	--message file://etc/sns-test.json

db-creds: export PYTHONPATH=# hack for aws
db-creds: export PGUSER = $(shell aws secretsmanager get-secret-value --secret-id=db-user|awk '{print $$4}')
db-creds: export PGPASSWORD = $(shell aws secretsmanager get-secret-value --secret-id=db-password|awk '{print $$4}')
db-creds: export PGHOST = aip.c7eaoykysgcc.us-east-2.rds.amazonaws.com
db-creds: ## save db crendentials
	@cp /dev/null .creds \
	&& echo "export PGUSER=$(PGUSER)" >> .creds  \
	&& echo "export PGPASSWORD=$(PGPASSWORD)" >> .creds \
	&& echo "export PGHOST=$(PGHOST)" >> .creds
	@echo ".creds created"


