NAME = taskd
VERSION = latest
SOURCE_URL = http://taskwarrior.org/download/$(NAME)-$(VERSION).tar.gz
PACKAGE_URL = http://taskwarrior.org/
PACKAGE_DESCRIPTION = Server component of Taskwarrior.
LICENSE = MIT
ITERATION = 1

BUILD_DIR := $(CURDIR)/build
CACHE_DIR = cache
PACKAGE_DIR = pkg
TARBALL = $(CACHE_DIR)/$(notdir $(SOURCE_URL))
SOURCE_DIR = $(CACHE_DIR)/$(NAME)-$(VERSION)
PACKAGE_TYPE = deb
PREFIX = /usr/local
RELATIVE_PREFIX := $(patsubst /%,%,$(PREFIX))

.PHONY: all
all: $(PACKAGE_DIR)

$(BUILD_DIR) $(CACHE_DIR):
	mkdir -p $@

.PRECIOUS: $(TARBALL)
$(TARBALL): | $(CACHE_DIR)
	wget -N -c --progress=dot:binary $(SOURCE_URL) -P $(CACHE_DIR)

$(SOURCE_DIR): $(TARBALL) | $(CACHE_DIR)
	tar xf $< -C $(CACHE_DIR)
ifeq ($(VERSION),latest)
	$(eval VERSION := $(patsubst $(NAME)-%/,%,$(dir $(shell tar tf $< | head -1))))
endif

$(SOURCE_DIR)/Makefile: | $(SOURCE_DIR)
	cd $(SOURCE_DIR) && cmake -DCMAKE_BUILD_TYPE=release .

$(SOURCE_DIR)/src/$(NAME): $(SOURCE_DIR)/Makefile
	$(MAKE) -C $(SOURCE_DIR)

$(BUILD_DIR)/usr/local/bin/$(NAME): | $(SOURCE_DIR)/src/$(NAME)
	$(MAKE) -C $(SOURCE_DIR) install DESTDIR=$(BUILD_DIR)

$(PACKAGE_DIR): $(BUILD_DIR)/usr/local/bin/$(NAME)
	$(eval roots = $(shell cd $(BUILD_DIR) && find $(RELATIVE_PREFIX) -mindepth 1 -maxdepth 1))
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
