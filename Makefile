-include custom.mk

.PHONY: help
help:
	@echo 'usage: make install ASUS_HOST=<your-nas-host>'
	@echo '<your-nas-host> needs to be able to connect through rsync or ssh.'

PREFIX_2_DIGIT ?= 55
init_file = S$(PREFIX_2_DIGIT)tailscale

.PHONY: install
install: tailscaled tailscale install.sh | $(init_file)
	$(if $(ASUS_HOST),,$(error ASUS_HOST variable is not defined))
	@set -eu; \
	remote_temp_dir=$$(ssh $(ASUS_HOST) -- mktemp -d); \
	if [[ -z "$$remote_temp_dir" ]] ; then \
		echo 'cannot create a temporary directory on `$(ASUS_HOST)`'; \
		exit 1; \
	fi; \
	set -v; \
	rsync -rltv $^ $(init_file) $(ASUS_HOST):$${remote_temp_dir}/; \
	set +v; \
	echo "warn: Don't forget exec \`$${remote_temp_dir}/install.sh $(init_file)\` on remote host to install"

$(init_file): SXXtailscale.template
	cp -a $< $@

tailscale tailscaled: $(tailscale.tgz)
	tar --strip-components 1 -xmvzf $< $(basename $<)/$@

$$(tailscale.tgz):
	curl -L $(TGZ_URL) -O

.PHONY: clean
clean:
	rm -f *.tgz $(init_file) tailscale tailscaled

.SECONDEXPANSION:
# default is latest
VER ?= $(shell curl -s https://api.github.com/repos/tailscale/tailscale/releases/latest | perl -nle '/"name":\s*"(.+)"/ and print $$1')
TGZ_URL = https://pkgs.tailscale.com/stable/tailscale_$(VER)_arm64.tgz
tailscale.tgz = $(notdir $(TGZ_URL))
