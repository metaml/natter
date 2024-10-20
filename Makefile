.DEFAULT_GOAL = help

ACCOUNT_ID := 975050288432
AWS := PYTHONPATH= aws # aws and openai dependency conflict with urllib3

run: export AWS_DEFAULT_REGION = us-east-2
run: ## run ami, rest server
	./app/ami.py

run-dev: export MODE = DEV
run-dev: ## run aip, rest server in dev mode
	./app/ami.py

# nix build --debug --verbose -L .#dist-files
build: ## build python package
	nix build # --impure --debug

lambda: push lambda-update ## push image and update lambda

push: image image-push ## * make and push docker-image to ecr; update lambda *

image: ## docker image
	nix build --impure --verbose --option sandbox relaxed .#docker

install: ## @ install ami flake @
	nix profile install #ami

install-app: ## install javascript client
	rsync --delete --archive static/ /static/

install-cert: ## install self-signed ssl cert
	cp -f etc/*.pem /etc

remove: ## @ remove ami flake @
	nix profile remove #ami

clean: ## clean
	find . -name \*~ | xargs rm -f

clobber: clean ## clobber dev env
	rm -rf venv/*

dev: ## @ nix develop @
	nix develop --impure

help: BLU = \033[1;34m
help: CYA = \033[1;36m
help: GRN = \033[1;32m
help: ORA = \033[0;33m# looks yellow
help: PRP = \033[1;35m
help: RED = \033[1;31m
help: YEL = \033[1;33m
help: CLR = \033[0m# clear, no color
help: ## * help
	-@printf "$(RED)note$(CLR): \"*\" updates AWS\n" ''
	-@printf "%-6s\"@\" indpendent of nix develop\n" ""
	-@grep --extended-regexp '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sed 's/^Makefile://1' \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "$(BLU)%-18s$(CLR) %s\n", $$1, $$2}'

login-aws: ## login to aws to fetch/refresh token
	PYTHONPATH= $(AWS) sso login # AdministratorAccess-975050288432

# useful utlities below

image-push: REGION = us-east-2
image-push: DOCKER_LOGIN = $(shell $(AWS) ecr get-login-password --region $(REGION))
image-push: ## * push image to ecr *
	docker tag ami-lambda:latest $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/ami-lambda:latest
	$(AWS) ecr get-login-password --region $(REGION) \
	| docker login --username AWS --password-stdin $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com
	docker push $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/ami-lambda:latest

image-load: ## load docker image
	docker load < result

image-run: ## run the image
	docker run --platform linux/am64 --interactive --tty --rm ami-lambda

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
	--topic-arn "arn:aws:sns:us-east-2:975050288432:aip" \
	--message file://etc/sns-test.json

# sns-publish: ## publish a message to the aip sns-topic
# 	aws sns publish \
# 	--topic-arn "arn:aws:sns:us-east-2:975050288432:aip" \
# 	--message file://etc/msg.json

rsync: HOST = ec2-3-136-167-53.us-east-2.compute.amazonaws.com
rsync: ## rsync ami to ec2 instance
	rsync --verbose \
	--archive \
	--compress \
	--delete \
	--progress \
	--rsh='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' \
	. ec2-3-136-167-53.us-east-2.compute.amazonaws.com:ami
	ssh ami 'cd ami && chown -R root .'

export PGHOST =# aip.c7eaoykysgcc.us-east-2.rds.amazonaws.com

db-creds: ## save dev db crendentials
	cp /dev/null .creds
	echo 'export PGUSER=aip-dev' > .creds
	$(AWS) secretsmanager get-secret-value --secret-id=db-password | head -1 | awk '{ print "export PGPASSWORD="$$4 }' >> .creds
	echo 'export PGHOST=' >> .creds
	@echo ".creds created"

db-creds-rds: ## save rds db crendentials
	cp /dev/null .creds-rds
	$(AWS) secretsmanager get-secret-value --secret-id=db-user | head -1 | awk '{ print "export PGUSER="$$4 }' >> .creds-rds
	$(AWS) secretsmanager get-secret-value --secret-id=db-password | head -1 | awk '{ print "export PGPASSWORD="$$4 }' >> .creds-rds
	echo 'export PGHOST=aip.c7eaoykysgcc.us-east-2.rds.amazonaws.com' >> .creds-rds
	@echo ".creds-rds created"


psql-rds: ## connect to rds instance--"make db-creds" at least once
	source ./.creds-rds && psql

psql: ## connect to rds instance--"make db-creds" at least once
	source ./.creds && psql

db-start: ## start dev database
	pg_ctl --pgdata=.ami-dev-db --log=/tmp/ami-dev-db.log start

db-stop: ## start dev database
	pg_ctl --pgdata=.ami-dev-db stop

db-init: ## init postgresql for development
	source ./.creds && \
	initdb --username="$${PGUSER}" \
	        --encoding=UTF8 \
	        --locale=en_US.UTF-8 \
	        --pwfile=.password-db \
	        --pgdata=.ami-dev-db

db-create:
	source ./.creds && \
	createdb aip-dev --template=template0 \
			 --owner=$(PGUSER) \
			 --username="$(PGUSER)" \
			 --encoding=UTF8 \
			 --locale=en_US.UTF-8

ssl-cert: ## create a self signed cert for SSL
	openssl req -x509 -newkey rsa:4096 -nodes -out etc/cert.pem -keyout etc/key.pem -days 3650

# Black        0;30     Dark Gray     1;30
# Red          0;31     Light Red     1;31
# Green        0;32     Light Green   1;32
# Brown/Orange 0;33     Yellow        1;33
# Blue         0;34     Light Blue    1;34
# Purple       0;35     Light Purple  1;35
# Cyan         0;36     Light Cyan    1;36
# Light Gray   0;37     White         1;37
