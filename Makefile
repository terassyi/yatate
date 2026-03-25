IMAGE := yatate
YATATE_DIR := $(shell pwd)

.PHONY: build run test test-encrypt shell clean install install-full

build:
	docker build -t $(IMAGE) .

run:
	docker run --rm -it \
		-v $(YATATE_DIR):/home/testuser/yatate \
		$(IMAGE) fish

test:
	docker run --rm \
		-v $(YATATE_DIR):/home/testuser/yatate \
		$(if $(GITHUB_TOKEN),-e GITHUB_TOKEN=$(GITHUB_TOKEN) -e AQUA_GITHUB_TOKEN=$(GITHUB_TOKEN),) \
		$(IMAGE) bash -c "/home/testuser/yatate/scripts/test.sh && /home/testuser/yatate/scripts/test-tools.sh"

test-encrypt:
	docker run --rm \
		-v $(YATATE_DIR):/home/testuser/yatate \
		$(if $(GITHUB_TOKEN),-e GITHUB_TOKEN=$(GITHUB_TOKEN) -e AQUA_GITHUB_TOKEN=$(GITHUB_TOKEN),) \
		$(IMAGE) bash -c "\
			REQUIRE_KEY=1 /home/testuser/yatate/scripts/setup-test-key.sh && \
			/home/testuser/yatate/scripts/test.sh && \
			/home/testuser/yatate/scripts/test-tools.sh"

shell:
	docker run --rm -it \
		-v $(YATATE_DIR):/home/testuser/yatate \
		-e GITHUB_TOKEN=$(shell gh auth token) \
		$(IMAGE) bash

clean:
	docker rmi -f $(IMAGE)

install:
	chezmoi init --apply --source=$(YATATE_DIR) --exclude=encrypted

install-full:
	chezmoi init --apply --source=$(YATATE_DIR)
