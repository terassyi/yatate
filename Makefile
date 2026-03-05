IMAGE := yatate
YATATE_DIR := $(shell pwd)

.PHONY: build run test shell clean install

build:
	docker build -t $(IMAGE) .

run:
	docker run --rm -it \
		-v $(YATATE_DIR):/home/testuser/yatate \
		$(IMAGE) fish

test:
	docker run --rm \
		-v $(YATATE_DIR):/home/testuser/yatate \
		$(if $(GITHUB_TOKEN),-e GITHUB_TOKEN=$(GITHUB_TOKEN),) \
		$(IMAGE) bash -c "/home/testuser/yatate/scripts/test.sh && /home/testuser/yatate/scripts/test-tools.sh"

shell:
	docker run --rm -it \
		-v $(YATATE_DIR):/home/testuser/yatate \
		$(IMAGE) bash

clean:
	docker rmi -f $(IMAGE)

install:
	chezmoi init --apply --source=$(YATATE_DIR)
