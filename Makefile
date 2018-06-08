SHELL                    := /bin/bash
BUILD_DIR                := .build
STAGE                    ?= dev
LAMBDA_HANDLERS_DIR_NAME ?= lambda
SERVICE_DIR              ?= $(CURDIR)
ENV_FILE_NAME            ?= env-$(STAGE).list

GREEN                    := \e[32m
NC                       := \e[0m

define find_recursive
$(shell find $1 -iname "$2")
endef

define print
	@echo -e '$(GREEN)$1$(NC)'
endef

define get_all_service_lambda_handlers_dirs
$(shell \
	service_dir=$(SERVICE_DIR) && \
	handlers_dirs=`ls -d $$service_dir/$(LAMBDA_HANDLERS_DIR_NAME)/*` && \
	echo `echo $$handlers_dirs | sed "s|$$service_dir/||g"` \
)
endef

define get_go_package
$(shell echo $(SERVICE_DIR) | sed "s|.*/src/||g")
endef

.PRECIOUS: \
	$(BUILD_DIR)/vendor \
	$(BUILD_DIR)/build \
	$(BUILD_DIR)/deploy

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/vendor: $(SERVICE_DIR)/Gopkg.toml $(SERVICE_DIR)/Gopkg.lock $(BUILD_DIR)
	$(call print,Installing deps ...)
	@dep ensure
	@touch $@

$(BUILD_DIR)/build: $(call find_recursive,$(SERVICE_DIR),*.go) $(BUILD_DIR)/vendor
	$(call print,Building service ...)
	@ set -e pipefail && for d in $(call get_all_service_lambda_handlers_dirs); \
	do \
		GOOS=linux go build -ldflags="-s -w" \
		-o $(SERVICE_DIR)/$$d/bin/main \
		$(call get_go_package)/$$d; \
	done
	@touch $@

$(BUILD_DIR)/deploy: $(BUILD_DIR)/build serverless.yml
	$(call print,Deploying service ...)
	@source $(ENV_FILE_NAME); serverless deploy --stage $(STAGE)
	@touch $@

.PHONY: \
	vendor \
	build \
	deploy \
	remove \
	tail-logs

vendor: $(BUILD_DIR)/vendor
	$(call print,Deps installed)

build: $(BUILD_DIR)/build
	$(call print,Service successfully built)

deploy: $(BUILD_DIR)/deploy
	$(call print,Service successfully deployed)

remove:
	$(call print,Removing service...)
	@serverless remove --stage $(STAGE)
	$(call print,Service successfully deployed)

tail-logs:
	serverless logs -tail -f $(f) --stage $(STAGE)
