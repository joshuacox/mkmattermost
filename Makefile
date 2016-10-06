.PHONY: all help build run builddocker rundocker kill rm-image rm clean enter logs

all: help

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""  This is merely a base image for usage read the README file
	@echo ""   1. make run       - build and run docker container

temp: init

init: MATTERMOST_RESET_SALT MATTERMOST_SECRET_KEY MATTERMOST_INVITE_SALT MATTERMOST_LINK_SALT TAG IP SMTP_HOST SMTP_PORT SMTP_PASS SMTP_USER DB_USER DB_NAME DB_PASS NAME PORT rmall runpostgresqlinit runredisinit runmattermostinit

run: TAG IP MATTERMOST_RESET_SALT MATTERMOST_SECRET_KEY MATTERMOST_INVITE_SALT MATTERMOST_LINK_SALT SMTP_DOMAIN  SMTP_HOST SMTP_PORT SMTP_PASS SMTP_USER DB_NAME DB_PASS NAME PORT rmall runpostgresql runredis runmattermost

next: grab clean run

builder: build tag push

runredisinit:
	$(eval NAME := $(shell cat NAME))
	docker run --name $(NAME)-redis-init \
	-d \
	--cidfile="redisinitCID" \
	redis \
	redis-server --appendonly yes

runpostgresqlinit: postgresqlinitCID

postgresqlinitCID: REGISTRY REGISTRY_PORT
	$(eval NAME := $(shell cat NAME))
	$(eval REGISTRY := $(shell cat REGISTRY))
	$(eval REGISTRY_PORT := $(shell cat REGISTRY_PORT))
	$(eval DB_USER := $(shell cat DB_USER))
	$(eval DB_PASS := $(shell cat DB_PASS))
	$(eval DB_NAME := $(shell cat DB_NAME))
	docker run \
	--name=$(NAME)-postgresql-init \
	-d \
	--cidfile="postgresqlinitCID" \
	$(REGISTRY):$(REGISTRY_PORT)/$(NAME)/db:latest

runmattermostinit: REGISTRY REGISTRY_PORT
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	$(eval REGISTRY := $(shell cat REGISTRY))
	$(eval REGISTRY_PORT := $(shell cat REGISTRY_PORT))
	$(eval MATTERMOST_LINK_SALT := $(shell cat MATTERMOST_LINK_SALT))
	$(eval MATTERMOST_SECRET_KEY := $(shell cat MATTERMOST_SECRET_KEY))
	$(eval MATTERMOST_RESET_SALT := $(shell cat MATTERMOST_RESET_SALT))
	$(eval MATTERMOST_INVITE_SALT := $(shell cat MATTERMOST_INVITE_SALT))
	$(eval IP := $(shell cat IP))
	$(eval PORT := $(shell cat PORT))
	$(eval DB_NAME := $(shell cat DB_NAME))
	$(eval DB_USER := $(shell cat DB_USER))
	$(eval DB_PASS := $(shell cat DB_PASS))
	$(eval SMTP_PORT := $(shell cat SMTP_PORT))
	$(eval SMTP_HOST := $(shell cat SMTP_HOST))
	$(eval SMTP_PASS := $(shell cat SMTP_PASS))
	$(eval SMTP_USER := $(shell cat SMTP_USER))
	docker run --name=$(NAME) \
	-d \
	--link=$(NAME)-postgresql-init:postgresql \
	--link=$(NAME)-redis-init:redis \
	--publish=$(IP):$(PORT):80 \
	--env="MATTERMOST_LINK_SALT=$(MATTERMOST_LINK_SALT)" \
	--env="MATTERMOST_SECRET_KEY=$(MATTERMOST_SECRET_KEY)" \
	--env="MATTERMOST_RESET_SALT=$(MATTERMOST_RESET_SALT)" \
	--env="MATTERMOST_INVITE_SALT=$(MATTERMOST_INVITE_SALT)" \
	--env="DB_ADAPTER=postgresql" \
	--env="DB_HOST=postgresql" \
	--env="DB_NAME=$(DB_NAME)" \
	--env="DB_USER=$(DB_USER)" \
	--env="DB_PASS=$(DB_PASS)" \
	--env="SMTP_HOST=$(SMTP_HOST)" \
	--env="SMTP_PORT=$(SMTP_PORT)" \
	--env="SMTP_USER=$(SMTP_USER)" \
	--env="SMTP_PASS=$(SMTP_PASS)" \
	--env="SMTP_SECURITY=$(SMTP_TLS)" \
	--env="MATTERMOST_SUPPORT_EMAIL=webmaster@$(SMTP_DOMAIN)" \
	--env='REDIS_URL=redis://redis:6379/12' \
	--cidfile="mattermostinitCID" \
	$(REGISTRY):$(REGISTRY_PORT)/$(NAME)/app:latest

#	sameersbn/mattermost:2.6-latest
# used to be last line above --> 	-t joshuacox/mattermostinit
#--publish=$(PORT):80 \

runredis:
	$(eval NAME := $(shell cat NAME))
	$(eval REDIS_DATADIR := $(shell cat REDIS_DATADIR))
	docker run --name $(NAME)-redis \
	-d \
	--cidfile="redisCID" \
	--volume=$(REDIS_DATADIR):/data \
	redis \
	redis-server --appendonly yes

runpostgresql: REGISTRY REGISTRY_PORT
	$(eval NAME := $(shell cat NAME))
	$(eval REGISTRY := $(shell cat REGISTRY))
	$(eval REGISTRY_PORT := $(shell cat REGISTRY_PORT))
	$(eval DB_USER := $(shell cat DB_USER))
	$(eval DB_PASS := $(shell cat DB_PASS))
	$(eval DB_NAME := $(shell cat DB_NAME))
	$(eval POSTGRESQL_DATADIR := $(shell cat POSTGRESQL_DATADIR))
	docker run \
	--name=$(NAME)-postgresql \
	-d \
	--cidfile="postgresqlCID" \
	--volume=$(POSTGRESQL_DATADIR):/var/lib/postgresql/data \
	--volume=/etc/localtime:/etc/localtime:ro \
	$(REGISTRY):$(REGISTRY_PORT)/$(NAME)/db:latest

runmattermost: REGISTRY REGISTRY_PORT WEBSOCKET_PORT
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	$(eval REGISTRY := $(shell cat REGISTRY))
	$(eval REGISTRY_PORT := $(shell cat REGISTRY_PORT))
	$(eval MATTERMOST_LINK_SALT := $(shell cat MATTERMOST_LINK_SALT))
	$(eval MATTERMOST_SECRET_KEY := $(shell cat MATTERMOST_SECRET_KEY))
	$(eval MATTERMOST_RESET_SALT := $(shell cat MATTERMOST_RESET_SALT))
	$(eval MATTERMOST_INVITE_SALT := $(shell cat MATTERMOST_INVITE_SALT))
	$(eval IP := $(shell cat IP))
	$(eval PORT := $(shell cat PORT))
	$(eval WEBSOCKET_PORT := $(shell cat WEBSOCKET_PORT))
	$(eval MATTERMOST_DATADIR := $(shell cat MATTERMOST_DATADIR))
	$(eval DB_NAME := $(shell cat DB_NAME))
	$(eval DB_USER := $(shell cat DB_USER))
	$(eval DB_PASS := $(shell cat DB_PASS))
	$(eval SMTP_PASS := $(shell cat SMTP_PASS))
	$(eval SMTP_USER := $(shell cat SMTP_USER))
	$(eval SMTP_PORT := $(shell cat SMTP_PORT))
	$(eval SMTP_HOST := $(shell cat SMTP_HOST))
	$(eval SMTP_TLS := $(shell cat SMTP_TLS))
	$(eval SMTP_DOMAIN := $(shell cat SMTP_DOMAIN))
	docker run --name=$(NAME) \
	-d \
	--link=$(NAME)-postgresql:postgresql \
	--link=$(NAME)-redis:redis \
	--publish=$(IP):$(PORT):80 \
	--publish=$(IP):$(WEBSOCKET_PORT):8065 \
	--env="MATTERMOST_LINK_SALT=$(MATTERMOST_LINK_SALT)" \
	--env="MATTERMOST_SECRET_KEY=$(MATTERMOST_SECRET_KEY)" \
	--env="MATTERMOST_RESET_SALT=$(MATTERMOST_RESET_SALT)" \
	--env="MATTERMOST_INVITE_SALT=$(MATTERMOST_INVITE_SALT)" \
	--env="DB_ADAPTER=postgresql" \
	--env="DB_HOST=postgresql" \
	--env="DB_NAME=$(DB_NAME)" \
	--env="DB_USER=$(DB_USER)" \
	--env="DB_PASS=$(DB_PASS)" \
	--env="SMTP_HOST=$(SMTP_HOST)" \
	--env="SMTP_PORT=$(SMTP_PORT)" \
	--env="SMTP_USER=$(SMTP_USER)" \
	--env="SMTP_PASS=$(SMTP_PASS)" \
	--env="SMTP_SECURITY=$(SMTP_TLS)" \
	--env="MATTERMOST_SUPPORT_EMAIL=webmaster@$(SMTP_DOMAIN)" \
	--env='REDIS_URL=redis://redis:6379/12' \
	--volume=$(MATTERMOST_DATADIR)/data:/mattermost/data \
	--volume=$(MATTERMOST_DATADIR)/config:/mattermost/config \
	--volume=/etc/localtime:/etc/localtime:ro \
	--cidfile="mattermostCID" \
	$(REGISTRY):$(REGISTRY_PORT)/$(NAME)/app:latest

kill:
	-@docker kill `cat mattermostCID`
	-@docker kill `cat postgresqlCID`
	-@docker kill `cat postgresqlCID`
	-@docker kill `cat redisCID`

killinit:
	-@docker kill `cat mattermostinitCID`
	-@docker kill `cat postgresqlinitCID`
	-@docker kill `cat postgresqlinitCID`
	-@docker kill `cat redisinitCID`

rm-redimage:
	-@docker rm `cat mattermostCID`

rm-initimage:
	-@docker rm `cat mattermostinitCID`
	-@docker rm `cat postgresqlinitCID`
	-@docker rm `cat postgresqlinitCID`
	-@docker rm `cat redisinitCID`

rm-image:
	-@docker rm `cat mattermostCID`
	-@docker rm `cat postgresqlCID`
	-@docker rm `cat postgresqlCID`
	-@docker rm `cat redisCID`

rm-redcids:
	-@rm mattermostCID

rm-initcids:
	-@rm mattermostinitCID
	-@rm postgresqlinitCID
	-@rm postgresqlinitCID
	-@rm redisinitCID

rm-cids:
	-@rm mattermostCID
	-@rm postgresqlCID
	-@rm postgresqlCID
	-@rm redisCID

rmall: kill rm-image rm-cids

rm: kill rm-redimage rm-redcids

rminit: killinit rm-initimage rm-initcids

clean:  rm rminit rmall

initenter:
	docker exec -i -t `cat mattermostinitCID` /bin/bash

enter:
	docker exec -i -t `cat mattermostCID` /bin/bash

pgenter:
	docker exec -i -t `cat postgresqlCID` /bin/bash

grab: grabmattermostdir grabpostgresqldatadir grabredisdatadir

postgresqlgrab: grabmattermostdir grabpostgresqldatadir

externgrab: grabmattermostdir grabredisdatadir

grabpostgresqldatadir:
	-@mkdir -p /exports/mattermost/postgresql/data
	docker cp `cat postgresqlinitCID`:/var/lib/postgresql/data  - |sudo tar -C /exports/mattermost/postgresql -pxf -
	echo /exports/mattermost/postgresql/data > POSTGRESQL_DATADIR

grabmattermostdir:
	-@mkdir -p /exports/mattermost
	docker cp `cat mattermostinitCID`:/mattermost/data  - |sudo tar -C /exports/mattermost/ -pxf -
	docker cp `cat mattermostinitCID`:/mattermost/config  - |sudo tar -C /exports/mattermost/ -pxf -
	echo /exports/mattermost > MATTERMOST_DATADIR

grabredisdatadir:
	-@mkdir -p /exports/mattermost/redis
	docker cp `cat redisinitCID`:/data  - |sudo tar -C /exports/mattermost/redis -pxf -
	echo /exports/mattermost/redis/data > REDIS_DATADIR

logs:
	docker logs -f `cat mattermostCID`

initlogs:
	docker logs -f `cat mattermostinitCID`

templogs: initlogs

NAME:
	@while [ -z "$$NAME" ]; do \
		read -r -p "Enter the name you wish to associate with this container [NAME]: " NAME; echo "$$NAME">>NAME; cat NAME; \
	done ;

TAG:
	@while [ -z "$$TAG" ]; do \
		read -r -p "Enter the tag you wish to associate with this mattermost sameersbn/mattermost for example [TAG]: " TAG; echo "$$TAG">>TAG; cat TAG; \
	done ;

IP:
	@while [ -z "$$IP" ]; do \
		read -r -p "Enter the IP you wish to associate with this mattermost [IP]: " IP; echo "$$IP">>IP; cat IP; \
	done ;

DB_ADAPTER:
	@while [ -z "$$DB_ADAPTER" ]; do \
		read -r -p "Enter the DB_ADAPTER you wish to associate with this container [DB_ADAPTER]: " DB_ADAPTER; echo "$$DB_ADAPTER">>DB_ADAPTER; cat DB_ADAPTER; \
	done ;

DB_PASS:
	@while [ -z "$$DB_PASS" ]; do \
		read -r -p "Enter the DB_PASS you wish to associate with this container [DB_PASS]: " DB_PASS; echo "$$DB_PASS">>DB_PASS; cat DB_PASS; \
	done ;

DB_NAME:
	@while [ -z "$$DB_NAME" ]; do \
		read -r -p "Enter the DB_NAME you wish to associate with this container [DB_NAME]: " DB_NAME; echo "$$DB_NAME">>DB_NAME; cat DB_NAME; \
	done ;

DB_HOST:
	@while [ -z "$$DB_HOST" ]; do \
		read -r -p "Enter the DB_HOST you wish to associate with this container [DB_HOST]: " DB_HOST; echo "$$DB_HOST">>DB_HOST; cat DB_HOST; \
	done ;

DB_USER:
	@while [ -z "$$DB_USER" ]; do \
		read -r -p "Enter the DB_USER you wish to associate with this container [DB_USER]: " DB_USER; echo "$$DB_USER">>DB_USER; cat DB_USER; \
	done ;

SMTP_PORT:
	@while [ -z "$$SMTP_PORT" ]; do \
		read -r -p "Enter the SMTP_PORT you wish to associate with this container [SMTP_PORT]: " SMTP_PORT; echo "$$SMTP_PORT">>SMTP_PORT; cat SMTP_PORT; \
	done ;

SMTP_DOMAIN:
	@while [ -z "$$SMTP_DOMAIN" ]; do \
		read -r -p "Enter the SMTP_DOMAIN you wish to associate with this container [SMTP_DOMAIN]: " SMTP_DOMAIN; echo "$$SMTP_DOMAIN">>SMTP_DOMAIN; cat SMTP_DOMAIN; \
	done ;

SMTP_TLS:
	@while [ -z "$$SMTP_TLS" ]; do \
		read -r -p "Enter the SMTP_TLS you wish to associate with this container [SMTP_TLS]: " SMTP_TLS; echo "$$SMTP_TLS">>SMTP_TLS; cat SMTP_TLS; \
	done ;

SMTP_STARTTLS:
	@while [ -z "$$SMTP_STARTTLS" ]; do \
		read -r -p "Enter the SMTP_STARTTLS you wish to associate with this container [SMTP_STARTTLS]: " SMTP_STARTTLS; echo "$$SMTP_STARTTLS">>SMTP_STARTTLS; cat SMTP_STARTTLS; \
	done ;

SMTP_OPENSSL_VERIFY_MODE:
	@while [ -z "$$SMTP_OPENSSL_VERIFY_MODE" ]; do \
		read -r -p "Enter the SMTP_OPENSSL_VERIFY_MODE you wish to associate with this container [SMTP_OPENSSL_VERIFY_MODE]: " SMTP_OPENSSL_VERIFY_MODE; echo "$$SMTP_OPENSSL_VERIFY_MODE">>SMTP_OPENSSL_VERIFY_MODE; cat SMTP_OPENSSL_VERIFY_MODE; \
	done ;

SMTP_HOST:
	@while [ -z "$$SMTP_HOST" ]; do \
		read -r -p "Enter the SMTP_HOST you wish to associate with this container [SMTP_HOST]: " SMTP_HOST; echo "$$SMTP_HOST">>SMTP_HOST; cat SMTP_HOST; \
	done ;

SMTP_PASS:
	@while [ -z "$$SMTP_PASS" ]; do \
		read -r -p "Enter the SMTP_PASS you wish to associate with this container [SMTP_PASS]: " SMTP_PASS; echo "$$SMTP_PASS">>SMTP_PASS; cat SMTP_PASS; \
	done ;

SMTP_USER:
	@while [ -z "$$SMTP_USER" ]; do \
		read -r -p "Enter the SMTP_USER you wish to associate with this container [SMTP_USER]: " SMTP_USER; echo "$$SMTP_USER">>SMTP_USER; cat SMTP_USER; \
	done ;

PORT:
	@while [ -z "$$PORT" ]; do \
		read -r -p "Enter the port you wish to associate with this container [PORT]: " PORT; echo "$$PORT">>PORT; cat PORT; \
	done ;

WEBSOCKET_PORT:
	@while [ -z "$$WEBSOCKET_PORT" ]; do \
		read -r -p "Enter the port you wish to associate with this container [WEBSOCKET_PORT]: " WEBSOCKET_PORT; echo "$$WEBSOCKET_PORT">>WEBSOCKET_PORT; cat WEBSOCKET_PORT; \
	done ;

exampledatadir:
	echo /exports/mattermost/postgresql/data > POSTGRESQL_DATADIR
	echo /exports/mattermost/mattermost/data > MATTERMOST_DATADIR
	echo /exports/mattermost/postgresql/data > REDIS_DATADIR

example: exampledatadir
	$(eval POSTGRESQL_DATADIR := $(shell cat POSTGRESQL_DATADIR))
	$(eval MATTERMOST_DATADIR := $(shell cat MATTERMOST_DATADIR))
	$(eval REDIS_DATADIR := $(shell cat REDIS_DATADIR))
	mkdir -p $(POSTGRESQL_DATADIR)
	mkdir -p $(MATTERMOST_DATADIR)
	mkdir -p $(REDIS_DATADIR)
	cp -i TAG.example TAG
	echo 'mkmattermost' > NAME
	curl icanhazip.com > IP
	echo 'TLS' > SMTP_TLS
	echo 'smtp.gmail.com' > SMTP_HOST
	echo 'www.gmail.com' > SMTP_DOMAIN
	echo '587' > SMTP_PORT
	echo '5080' > PORT
	echo 'mkmattermost' > DB_USER
	echo 'mkmattermostdb' > DB_NAME
	pwgen -Bsv1 32 > DB_PASS

MATTERMOST_SECRET_KEY:
	pwgen -Bsv1 64 > MATTERMOST_SECRET_KEY

MATTERMOST_LINK_SALT:
	pwgen -Bsv1 64 > MATTERMOST_LINK_SALT

MATTERMOST_RESET_SALT:
	pwgen -Bsv1 64 > MATTERMOST_RESET_SALT

MATTERMOST_INVITE_SALT:
	pwgen -Bsv1 64 > MATTERMOST_INVITE_SALT

build: TAG NAME
	$(eval TMP := $(shell mktemp -d --suffix=MATTERMOSTBLDTMP))
	$(eval TAG := $(shell cat TAG))
	$(eval NAME := $(shell cat NAME))
	cd $(TMP) ; \
	git clone https://github.com/mattermost/mattermost-docker ; \
	cd $(TMP)/mattermost-docker/db ; \
	docker build -t $(NAME)/db:latest . ; \
	cd $(TMP)/mattermost-docker/app ; \
	docker build -t $(NAME)/app:latest . ; \
	cd $(TMP)/mattermost-docker/web ; \
	docker build -t $(NAME)/web:latest . ; \
	ls $(TMP)/mattermost-docker
	docker images |grep $(NAME)
	rm  -Rf $(TMP)

tag: NAME REGISTRY REGISTRY_PORT
	$(eval NAME := $(shell cat NAME))
	$(eval REGISTRY := $(shell cat REGISTRY))
	$(eval REGISTRY_PORT := $(shell cat REGISTRY_PORT))
	docker tag $(NAME)/db:latest $(REGISTRY):$(REGISTRY_PORT)/$(NAME)/db:latest
	docker tag $(NAME)/app:latest $(REGISTRY):$(REGISTRY_PORT)/$(NAME)/app:latest
	docker tag $(NAME)/web:latest $(REGISTRY):$(REGISTRY_PORT)/$(NAME)/web:latest

push: NAME REGISTRY REGISTRY_PORT
	$(eval NAME := $(shell cat NAME))
	$(eval REGISTRY := $(shell cat REGISTRY))
	$(eval REGISTRY_PORT := $(shell cat REGISTRY_PORT))
	docker push $(REGISTRY):$(REGISTRY_PORT)/$(NAME)/db:latest
	docker push $(REGISTRY):$(REGISTRY_PORT)/$(NAME)/app:latest
	docker push $(REGISTRY):$(REGISTRY_PORT)/$(NAME)/web:latest

pull: NAME REGISTRY REGISTRY_PORT
	$(eval NAME := $(shell cat NAME))
	$(eval REGISTRY := $(shell cat REGISTRY))
	$(eval REGISTRY_PORT := $(shell cat REGISTRY_PORT))
	docker pull $(REGISTRY):$(REGISTRY_PORT)/$(NAME)/db:latest
	docker pull $(REGISTRY):$(REGISTRY_PORT)/$(NAME)/app:latest
	docker pull $(REGISTRY):$(REGISTRY_PORT)/$(NAME)/web:latest

REGISTRY:
	@while [ -z "$$REGISTRY" ]; do \
		read -r -p "Enter the registry you wish to associate with this container [REGISTRY]: " REGISTRY; echo "$$REGISTRY">>REGISTRY; cat REGISTRY; \
	done ;

REGISTRY_PORT:
	@while [ -z "$$REGISTRY_PORT" ]; do \
		read -r -p "Enter the port of the registry you wish to associate with this container, usually 5000 [REGISTRY_PORT]: " REGISTRY_PORT; echo "$$REGISTRY_PORT">>REGISTRY_PORT; cat REGISTRY_PORT; \
	done ;

