-include custom.mk

.PHONY: help
help:
	@echo 'usage: make install ASUS_HOST=<your-nas-host>'
	@echo '<your-nas-host> needs to be able to connect through rsync or ssh.'

PREFIX_2_DIGIT ?= 55
init_file = S$(PREFIX_2_DIGIT)tailscale
TARGET_TO_INSTALL = installed-on-$(ASUS_HOST)

.PHONY: install
install: $(TARGET_TO_INSTALL)

$(TARGET_TO_INSTALL): guard-install .WAIT tailscaled tailscale install.sh | $(init_file)
	@set -eu; \
	remote_temp_dir=$$(ssh $(ASUS_HOST) -- mktemp -d); \
	if [[ -z "$$remote_temp_dir" ]] ; then \
		echo 'cannot create a temporary directory on `$(ASUS_HOST)`'; \
		exit 1; \
	fi; \
	set -v; \
	rsync -rltv tailscaled tailscale install.sh $(init_file) $(ASUS_HOST):$${remote_temp_dir}/; \
	set +v; \
	echo "warn: Don't forget exec \`$${remote_temp_dir}/install.sh $(init_file)\` on remote host to install"
	touch $@

.PHONY: guard-install
guard-install:
	$(if $(ASUS_HOST),,$(error ASUS_HOST variable is not defined))

$(init_file): SXXtailscale.template
	cp -a $< $@

tailscale tailscaled: downloaded
	tar --strip-components 1 -xmvzf $(tailscale.tgz) $(basename $(tailscale.tgz))/$@


.INTERMEDIATE: ver-tmp
ver-tmp:
	curl -s https://api.github.com/repos/tailscale/tailscale/releases/latest | perl -nle '/"tag_name":\s*"v(.+)"/ and print $$1' > $@

ver: ver-tmp
	if [[ ! -e $@ ]] || ! cmp -s $@ $< ; then cat $< > $@ ; fi

.PHONY: ver-updated
ver-updated:
	$(MAKE) --always-make ver

TGZ_URL = https://pkgs.tailscale.com/stable/tailscale_$(shell cat ver 2> /dev/null || printf '<ver>')_arm64.tgz
tailscale.tgz = $(notdir $(TGZ_URL))

downloaded: ver
	curl -L $(TGZ_URL) -O
	touch $@

.PHONY: clean
clean:
	rm -f *.tgz $(init_file) tailscale tailscaled ver downloaded

# for backward-compatible
.WAIT:
