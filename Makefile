.PHONY: all help build run builddocker rundocker kill rm-image rm clean enter logs

all: up

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""  This is merely a base image for usage read the README file
	@echo ""   1. make run       - build and run docker container

up:
	docker-compose up -d --build
