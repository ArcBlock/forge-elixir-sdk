TOP_DIR=.
VERSION=$(strip $(shell cat version))


travis-init: dep
	@echo "Initialize software required for travis (normally ubuntu software)"

travis-deploy:
	@echo "Deploy the software by travis"
	@make release

precommit: pre-build build post-build test

travis: precommit

pre-build: dep
	@echo "Running scripts before the build..."

post-build:
	@echo "Running scripts after the build is done..."

build:
	@echo "Building the software..."
	@make format

format:
	@mix compile; mix format;

dep:
	@echo "Install dependencies required for this repo..."
	@mix deps.get

test:
	@echo "Running test suites..."
	@MIX_ENV=test make build
	@MIX_ENV=test mix test

dialyzer:
	mix dialyzer

run:
	@echo "Running the software..."
	@iex -S mix

include .makefiles/*.mk

.PHONY: build init travis-init install dep pre-build post-build all test dialyzer doc precommit travis run
