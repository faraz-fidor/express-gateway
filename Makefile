# Project namespace: fidor by default
NAMESPACE ?= loanservice
# Image name
NAME := express_gateway
# Docker registry
REGISTRY ?= dockerhub.fidorfzco.com:5000
# Docker image reference
IMG := ${REGISTRY}/${NAMESPACE}/${NAME}
# Fetch the git branch name if it is not provided
BRANCH ?= $$(git symbolic-ref --short HEAD)
# Create  an image tag based on the branch name
BRANCH_TAG := $$(echo ${BRANCH} | tr / _)
# Fetch the latest commit hash
COMMIT_HASH := $$(git rev-parse HEAD)
# Set build parameters
BUILD_PARAMS := --pull --label com.fidor.revision=${COMMIT_HASH}
# set proxy if exist
BUILD_ARGS := --build-arg http_proxy=${http_proxy}
# Get ruby version
RUBY_VERSION := $$(<.ruby-version)
# Get ruby gemset name
RUBY_GEMSET := $$(<.ruby-gemset)
# Bundler version related to project
BUNDLER_VERSION := $$(tail -n 1 Gemfile.lock | xargs)
# RVM version
RVM_VERSION := $$(rvm -v)

# Command for starting the container
COMMAND := web

# Always use login bash shell
SHELL := /bin/bash --login

# Exposed port
PORT := -p 3054:8080

# Environment variables needed to start container
CONTAINER_ENV = -e RAILS_ENV=production  -e RAILS_LOG_TO_STDOUT=true

# Make sure recipes are always executed
.PHONY: config build push run clean shell start rm stop

# Make the necessary configuration for the build
config:
	@echo "Running configuration ..."; \
	echo ${RVM_VERSION}; \
	rvm use ruby-${RUBY_VERSION} --install; \
	rvm gemset use ${RUBY_GEMSET}_${BRANCH_TAG} --create; \
	gem install bundler -v ${BUNDLER_VERSION}; \
	rm -rf .bundle; \
	rm -rf vendor/cache; \
	bundle package --all-platforms --all --no-install ; \
	rm -rf .bundle;

# Return the latest commit hash, useful for upstream pipeline
get_commit_hash:
	@echo ${COMMIT_HASH}

# Display build parameters
test_config:
	@echo "Testing configuration ..."; \
	echo ${BUILD_PARAMS}

# Build and tag Docker image
build: test_config
	@echo "Building Docker Image ..."; \
	echo "Branch: " ${BRANCH}; \
	echo "Commit hash: " ${COMMIT_HASH}; \
	docker build ${BUILD_PARAMS} ${BUILD_ARGS} -t ${IMG}:${COMMIT_HASH} . ; \
	docker tag ${IMG}:${COMMIT_HASH} ${IMG}:${BRANCH_TAG}

# Push Docker image
push:
	@echo "Pushing Docker image ..."; \
	docker push ${IMG}:${COMMIT_HASH}; \
	docker push ${IMG}:${BRANCH_TAG}; \
	echo "Pushed tag : ${BRANCH_TAG}"; \
	if [[ "${BRANCH}" == "master" ]]; then\
		docker tag ${IMG}:${COMMIT_HASH} ${IMG}:latest; \
		docker push ${IMG}:latest; \
		echo "Pushed tag : latest"; \
	fi

# Clean up the created images locally and remove rvm gemset
clean:
	@if [[ "${BRANCH}" == "master" ]]; then \
		docker rmi -f ${IMG}:latest; \
	fi; \
	docker rmi -f ${IMG}:${BRANCH_TAG}; \
	docker rmi -f ${IMG}:${COMMIT_HASH}; \
	rvm --force gemset delete ruby-${RUBY_VERSION}@${RUBY_GEMSET}_${BRANCH_TAG}

# Start a shell session inside docker container
shell:
	docker run --rm --name ${NAME}-${BRANCH_TAG} ${CONTAINER_ENV} -it ${PORT} ${IMG}:${COMMIT_HASH} sh

# Start a Docker container in the foreground
run:
	docker run --rm --name ${NAME}-${BRANCH_TAG} ${CONTAINER_ENV} -it ${PORT} ${IMG}:${COMMIT_HASH} ${COMMAND}

# Start Docker container in the background
start:
	docker run -d --name ${NAME}-${BRANCH_TAG} ${CONTAINER_ENV} ${PORT} ${IMG}:${COMMIT_HASH} ${COMMAND}

# Stop running Docker container
stop:
	docker stop ${NAME}-${BRANCH_TAG}

# Remove Docker container
rm:
	docker rm ${NAME}-${BRANCH_TAG}

# Release Docker image: build and push
release: config build
	$(MAKE)  push

