NAME = taskd
VERSION ?= 1.2.0
REPO = https://git.tasktools.org/scm/tm/$(NAME).git
PACKAGE_URL = http://taskwarrior.org/
PACKAGE_DESCRIPTION = Server component of Taskwarrior.
LICENSE = MIT
ITERATION ?= 1

BUILD_DIR := $(CURDIR)/build
CACHE_DIR = cache
PACKAGE_DIR = pkg
SOURCE_DIR = $(CACHE_DIR)/$(NAME)
PACKAGE_TYPE ?= deb
PREFIX ?= /usr/local

.PHONY: all
all: $(PACKAGE_DIR)

$(BUILD_DIR) $(CACHE_DIR):
	mkdir -p $@

$(SOURCE_DIR): | $(CACHE_DIR)
	cd $| && git clone --recursive -j2 --depth 1 $(REPO) -b $(VERSION)

$(SOURCE_DIR)/Makefile: | $(SOURCE_DIR)
	cd $(SOURCE_DIR) && cmake -DCMAKE_BUILD_TYPE=release -DCMAKE_INSTALL_PREFIX=$(PREFIX) .

$(SOURCE_DIR)/src/$(NAME): $(SOURCE_DIR)/Makefile
	$(MAKE) -C $(SOURCE_DIR)

$(BUILD_DIR)$(PREFIX)/bin/$(NAME): | $(SOURCE_DIR)/src/$(NAME)
	$(MAKE) -C $(SOURCE_DIR) install DESTDIR=$(BUILD_DIR)

$(PACKAGE_DIR): $(BUILD_DIR)$(PREFIX)/bin/$(NAME)
	$(eval roots = $(shell cd $(BUILD_DIR) && find $(patsubst /%,%,$(PREFIX)) -mindepth 1 -maxdepth 1))
	mkdir -p $@
	cd $@ && fpm -s dir -t $(PACKAGE_TYPE) -C $(BUILD_DIR) --force \
		--name $(NAME) --version $(VERSION) --iteration $(ITERATION) \
		--license "$(LICENSE)" --url $(PACKAGE_URL) --description "$(PACKAGE_DESCRIPTION)" \
		$(roots) || cd .. && rm -rf $@

.PHONY: clean distclean install
clean:
	rm -rf $(BUILD_DIR) $(CACHE_DIR)

distclean: clean
	rm -rf $(PACKAGE_DIR)

install: ~/pkgs
ifeq ($(PACKAGE_TYPE),deb)
	sudo dpkg -i $(PACKAGE_DIR)/$(NAME)*.$(PACKAGE_TYPE)
else
	sudo rpm -ivh $(PACKAGE_DIR)/$(NAME)*.$(PACKAGE_TYPE)
endif
	cp -a $(PACKAGE_DIR)/*.$(PACKAGE_TYPE) ~/pkgs/
