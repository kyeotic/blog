.PHONY: help run-blog blog deploy

HELP_FUNC = \
    %help; \
    while(<>) { \
        if(/^([a-z0-9_-]+):.*\#\#(?:@(\w+))?\s(.*)$$/) { \
            push(@{$$help{$$2}}, [$$1, $$3]); \
        } \
    }; \
    print "usage: make [target]\n"; \
    for ( sort keys %help ) { \
        print "$$_\n"; \
        printf("  %-20s %s\n", $$_->[0], $$_->[1]) for @{$$help{$$_}}; \
        print "\n"; \
    }

help:
	@perl -e '$(HELP_FUNC)' $(MAKEFILE_LIST)

run: ## Run in development mode
	docker-compose -f infrastructure/docker-compose.yaml up

sync-blog: ## update blog theme submodules
	git submodule update --init --recursive