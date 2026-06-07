# PTtool 测试镜像本地维护系统
# 用法: make test       — 一键完整测试（自动按需构建）
#       make test-nas   — NAS 仿真测试
#       make build      — 构建全部镜像
#       make list       — 查看本地镜像缓存
#       make rebuild    — 强制重新构建
#       make clean      — 删除本地测试镜像

SHELL := /bin/sh
PROJ  := $(CURDIR)/..

# 镜像名称
TEST_IMG := pttool-test
NAS_IMG  := pttool-nas

# 构建参数（本地用阿里云镜像加速，CI 环境用默认仓库）
ifeq ($(CI),true)
APK_MIRROR := dl-cdn.alpinelinux.org
else
APK_MIRROR ?= mirrors.aliyun.com
endif
BUILD_ARGS := --build-arg APK_MIRROR=$(APK_MIRROR)

# 依赖文件列表（变更时触发重建）
TEST_DEPS := docker/test_suite.Dockerfile test_suite.sh
NAS_DEPS  := docker/verify_nas.Dockerfile verify_nas.sh

# 校验和文件
TEST_CKSUM := .checksums/test_suite
NAS_CKSUM  := .checksums/verify_nas

# 默认目标：运行完整测试
.PHONY: test
test: build-test
	docker run --rm -v "$(PROJ):/pttool:ro" $(TEST_IMG)

# NAS 仿真测试
.PHONY: test-nas
test-nas: build-nas
	docker run --rm -v "$(PROJ):/pttool:ro" $(NAS_IMG)

# 构建全部镜像
.PHONY: build
build: build-test build-nas

# 构建测试镜像（带增量缓存）
.PHONY: build-test
build-test:
	@$(MAKE) _build NAME=$(TEST_IMG) DEPS="$(TEST_DEPS)" CKSUM=$(TEST_CKSUM) DOCKERFILE=docker/test_suite.Dockerfile

# 构建 NAS 镜像
.PHONY: build-nas
build-nas:
	@$(MAKE) _build NAME=$(NAS_IMG) DEPS="$(NAS_DEPS)" CKSUM=$(NAS_CKSUM) DOCKERFILE=docker/verify_nas.Dockerfile

# 内部构建逻辑
.PHONY: _build
_build:
	@mkdir -p .checksums; \
	CKSUM=$$(cat $(DEPS) 2>/dev/null | md5sum | cut -d' ' -f1); \
	SHORT=$$(echo "$$CKSUM" | cut -b1-8); \
	STORED=""; \
	[ -f $(CKSUM) ] && STORED=$$(cat $(CKSUM)); \
	if [ "$$CKSUM" = "$$STORED" ] && docker image inspect $(NAME) >/dev/null 2>&1; then \
		echo "  ✓ $(NAME): 缓存命中 ($$SHORT)"; \
	else \
		echo "  ▶ $(NAME): 构建中..."; \
		docker build $(BUILD_ARGS) -t $(NAME) -f $(DOCKERFILE) $(PROJ) 2>&1 | tail -1; \
		echo "$$CKSUM" > $(CKSUM); \
		echo "  ✓ $(NAME): 构建完成 ($$SHORT, 镜像: $(APK_MIRROR))"; \
	fi

# 强制重建
.PHONY: rebuild
rebuild:
	@rm -f $(TEST_CKSUM) $(NAS_CKSUM)
	@$(MAKE) build

# 查看本地镜像缓存
.PHONY: list
list:
	@echo "=== PTtool 测试镜像缓存 ==="; \
	for img in $(TEST_IMG) $(NAS_IMG); do \
		if docker image inspect "$$img" >/dev/null 2>&1; then \
			created=$$(docker image inspect "$$img" --format '{{.Created}}' | cut -d'.' -f1 | tr 'T' ' '); \
			size=$$(docker image inspect "$$img" --format '{{.Size}}' | numfmt --to=iec 2>/dev/null || docker image inspect "$$img" --format '{{.Size}}'); \
			echo "  ✓ $$img ($$created, $$size)"; \
		else \
			echo "  ✗ $$img (未构建)"; \
		fi; \
	done; \
	for ck in $(TEST_CKSUM) $(NAS_CKSUM); do \
		if [ -f "$$ck" ]; then \
			echo "    校验和: $$(cat $$ck)"; \
		fi; \
	done

# 删除镜像
.PHONY: clean
clean:
	@for img in $(TEST_IMG) $(NAS_IMG); do \
		if docker image inspect "$$img" >/dev/null 2>&1; then \
			docker rmi "$$img" 2>/dev/null && echo "  ✓ 已删除: $$img"; \
		fi; \
	done
	rm -f $(TEST_CKSUM) $(NAS_CKSUM)
	@echo "  ✓ 缓存已清除"
