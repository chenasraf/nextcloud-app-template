# SPDX-FileCopyrightText: Bernhard Posselt <dev@bernhard-posselt.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Nextcloud App Template — Makefile
# ---------------------------------
# A friendly, batteries-included Makefile for building and packaging a Nextcloud app
# that uses pnpm (JS) and Composer (PHP).
#
# Requirements:
#   - make, which, curl, tar
#   - pnpm (for JS build/lint/test)
#   - composer (optional; will auto-download local composer.phar if missing)
#
# Conventions:
#   - If no composer.json → Composer step is skipped.
#   - If no package.json (root) and js/package.json missing → pnpm step is skipped.
#   - JS build is delegated to your package.json scripts (tool-agnostic).
#
# Common recipes:
#   make build     → install deps & build
#   make dist      → build source + appstore tarballs
#   make test      → run PHP unit tests
#   make lint      → lint JS & PHP
#   make openapi   → generate OpenAPI JSON
#   make sign      → print signature for GitHub tarball
#   make release   → upload release to Nextcloud App Store
#

app_name=nextcloudapptemplate
repo_path=your-user/nextcloud-$(app_name)
build_tools_directory=$(CURDIR)/build/tools
source_build_directory=$(CURDIR)/build/artifacts/source
source_intermediate_directory=$(CURDIR)/build/artifacts/intermediate-source
source_package_name=$(source_build_directory)/$(app_name)
app_intermediate_directory=$(CURDIR)/build/artifacts/intermediate/$(app_name)
appstore_build_directory=$(CURDIR)/build/artifacts/appstore
appstore_package_name=$(appstore_build_directory)/$(app_name)
pnpm=$(shell which pnpm 2> /dev/null)
composer=$(shell which composer 2> /dev/null)
composer_phar=build/tools/composer.phar

# Default target: install deps & build JS (and PHP if composer.json exists)
all: build

# build:
#   - Composer install if composer.json exists (skips if vendor/ exists)
#   - pnpm install & build if package.json (root) or js/package.json exists
.PHONY: build
build:
ifneq (,$(wildcard $(CURDIR)/composer.json))
	make composer
endif
ifneq (,$(wildcard $(CURDIR)/package.json))
	make pnpm
endif
ifneq (,$(wildcard $(CURDIR)/js/package.json))
	make pnpm
endif

# composer:
#   - Use system composer if available, else download local composer.phar
#   - Skip install if vendor/ already exists
.PHONY: composer
composer:
ifeq (, $(composer))
	@echo "No composer command available, downloading a copy from the web"
	mkdir -p $(build_tools_directory)
	curl -sS https://getcomposer.org/installer | php
	mv composer.phar $(composer_phar)
endif
ifneq ("$(wildcard vendor)","")
	@echo "Vendor directory already exists, skipping composer install"
else
	@echo "Installing composer dependencies..."
	$(if $(composer),$(composer),php $(composer_phar)) install --prefer-dist
endif

# pnpm:
#   - Install JS deps (frozen lockfile)
#   - Run build via root package.json if present, else fallback to js/ subdir
.PHONY: pnpm
pnpm:
	pnpm install --frozen-lockfile
ifeq (,$(wildcard $(CURDIR)/package.json))
	cd js && $(pnpm) build
else
	pnpm build
endif

# clean:
#   - Remove build artifacts (but keep dependencies)
.PHONY: clean
clean:
	rm -rf ./build

# distclean:
#   - Run clean and also remove PHP/JS dependencies
.PHONY: distclean
distclean: clean
	rm -rf vendor
	rm -rf node_modules
	rm -rf js/vendor
	rm -rf js/node_modules

# dist:
#   - Build both source and appstore tarballs
.PHONY: dist
dist:
	make source
	make appstore

# source:
#   - Create a source tarball (full source, excludes dev/test artifacts)
#   - Output: build/artifacts/source/$(app_name).tar.gz
.PHONY: source
source:
	rm -rf $(source_build_directory)
	mkdir -p $(source_build_directory)
	rm -rf $(appstore_package_name).tar.gz
	rsync -vtr \
		--exclude="**/.git/**/*" \
		--exclude="build" \
		--exclude="tests" \
		--exclude="src" \
		--exclude="js/node_modules" \
		--exclude="node_modules" \
		--exclude="*.log" \
		--exclude="dist/js/*.log" \
		$(CURDIR)/ $(source_intermediate_directory)
	cd $(source_intermediate_directory) && \
	tar czf $(source_package_name).tar.gz ../$(app_name)

# appstore:
#   - Create an App Store tarball (strips tests, dotfiles, dev configs)
#   - Output: build/artifacts/appstore/$(app_name).tar.gz
.PHONY: appstore
appstore:
	rm -rf $(appstore_build_directory)
	mkdir -p $(app_intermediate_directory)
	mkdir -p $(appstore_build_directory)
	rm -rf $(appstore_package_name).tar.gz
	rsync -vtr \
		--exclude="**/.git/**/*" \
		--exclude="**/.github/**/*" \
		--exclude="build" \
		--exclude="tests" \
		--exclude="Makefile" \
		--exclude="*.log" \
		--exclude="phpunit*xml" \
		--exclude="composer.*" \
		--exclude="node_modules" \
		--exclude="dist/js/node_modules" \
		--exclude="dist/js/tests" \
		--exclude="dist/js/test" \
		--exclude="dist/js/*.log" \
		--exclude="dist/js/package.json" \
		--exclude="dist/js/bower.json" \
		--exclude="dist/js/karma.*" \
		--exclude="dist/js/protractor.*" \
		--exclude="package.json" \
		--exclude="bower.json" \
		--exclude="karma.*" \
		--exclude="protractor\.*" \
		--exclude=".*" \
		--exclude="dist/js/.*" \
		--exclude="src" \
		$(CURDIR)/ $(app_intermediate_directory)
	cd $(app_intermediate_directory) && \
	tar czf $(appstore_package_name).tar.gz ../$(app_name)

# test:
#   - Run PHP unit tests (standard + optional integration config)
.PHONY: test
test: composer
	$(CURDIR)/vendor/phpunit/phpunit/phpunit -c tests/phpunit.xml
	( test ! -f tests/phpunit.integration.xml ) || $(CURDIR)/vendor/phpunit/phpunit/phpunit -c tests/phpunit.integration.xml

# lint:
#   - Lint JS via pnpm and PHP via composer script "lint"
.PHONY: lint
lint:
	pnpm lint
	$(composer_phar) run lint

# php-cs-fixer:
#   - Fix staged PHP files with PHP-CS-Fixer shim (checks syntax first)
.PHONY: php-cs-fixer
php-cs-fixer:
	@echo "\x1b[33mFixing PHP files...\x1b[0m"
	@FILES=$$(git diff --cached --name-only --diff-filter=ACM | grep '\.php$$' | grep -v '^gen/'); \
	if [ -z "$$FILES" ]; then \
		echo "No PHP files staged."; \
	else \
		echo "Running CS fixer on:" $$FILES; \
		php -l $$FILES || exit 1; \
		PHP_CS_FIXER_IGNORE_ENV=true php vendor-bin/cs-fixer/vendor/php-cs-fixer/shim/php-cs-fixer.phar --config=.php-cs-fixer.dist.php fix $$FILES || exit 1; \
	fi

# format:
#   - Format JS and PHP (composer script "cs:fix")
.PHONY: format
format:
	pnpm format
	PHP_CS_FIXER_IGNORE_ENV=true $(composer_phar) run cs:fix

# openapi:
#   - Generate OpenAPI spec via composer script "openapi"
#   - Output: build/openapi/openapi.json
.PHONY: openapi
openapi:
	@echo "\x1b[33mGenerating OpenAPI documentation...\x1b[0m"
	$(if $(composer),$(composer),php $(composer_phar)) run openapi
	@echo "\x1b[32mOpenAPI documentation generated at build/openapi/openapi.json\x1b[0m"

# sign:
#   - Print a base64 SHA-512 signature for the release tarball from GitHub.
#   - Requires a private key at ~/.nextcloud/certificates/$(app_name).key
#   - Reads version from version.txt
.PHONY: sign
sign:
	@VERSION="$$(cat version.txt)"; \
	TMPF="$$(mktemp)"; \
	KEY_FILE=~/.nextcloud/certificates/$(app_name).key; \
	if [ ! -f "$$KEY_FILE" ]; then \
		echo "\x1b[31m❌ Error: Private key not found at $$KEY_FILE\x1b[0m"; \
		exit 1; \
	fi; \
	echo "\x1b[33mSigning version $${VERSION}\x1b[0m"; \
	echo "\x1b[33mDownloading archive...\x1b[0m"; \
	curl -L https://github.com/$(repo_path)/releases/download/v$${VERSION}/$(app_name)-v$${VERSION}.tar.gz -o "$${TMPF}"; \
	FILESIZE=$$(stat -f%z "$${TMPF}" 2>/dev/null || stat -c%s "$${TMPF}"); \
	if [ "$${FILESIZE}" -lt 10240 ]; then \
		echo "\x1b[31mError: Downloaded file is too small (<10KB, actual: $${FILESIZE} bytes)\x1b[0m"; \
		rm -rf "$${TMPF}"; \
		exit 1; \
	fi; \
	echo "\x1b[33mSigning with key $$KEY_FILE\x1b[0m"; \
	echo; \
	echo "\x1b[32mDownload URL:\x1b[0m https://github.com/$(repo_path)/releases/download/v$${VERSION}/$(app_name)-v$${VERSION}.tar.gz"; \
	echo "\x1b[32mSignature:\x1b[0m"; \
	openssl dgst -sha512 -sign "$$KEY_FILE" "$${TMPF}" | openssl base64; \
	rm -rf "$${TMPF}"

# release:
#   - Upload release to Nextcloud App Store using NEXTCLOUD_API_TOKEN
#   - Downloads tarball from GitHub, signs it, and POSTs to App Store
.PHONY: release
release:
	@VERSION="$$(cat version.txt)"; \
	if [ -z "$$NEXTCLOUD_API_TOKEN" ]; then \
		printf "\x1b[33mNEXTCLOUD_API_TOKEN not set. Enter token: \x1b[0m"; \
		read -r NEXTCLOUD_API_TOKEN; \
	fi; \
	if [ -z "$$NEXTCLOUD_API_TOKEN" ]; then \
		echo "\x1b[31m❌ Error: NEXTCLOUD_API_TOKEN is missing\x1b[0m"; \
		exit 1; \
	else \
		echo "\x1b[32m✅ Using provided NEXTCLOUD_API_TOKEN\x1b[0m"; \
	fi; \
	TMPF="$$(mktemp)"; \
	DOWNLOAD_URL="https://github.com/$(repo_path)/releases/download/v$${VERSION}/$(app_name)-v$${VERSION}.tar.gz"; \
	KEY_FILE=~/.nextcloud/certificates/$(app_name).key; \
	if [ ! -f "$$KEY_FILE" ]; then \
		echo "\x1b[31m❌ Error: Private key not found at $$KEY_FILE\x1b[0m"; \
		exit 1; \
	fi; \
	echo "\x1b[33mDownloading archive for version $${VERSION}...\x1b[0m"; \
	curl -L "$${DOWNLOAD_URL}" -o "$${TMPF}"; \
	FILESIZE=$$(stat -f%z "$${TMPF}" 2>/dev/null || stat -c%s "$${TMPF}"); \
	if [ "$${FILESIZE}" -lt 10240 ]; then \
		echo "\x1b[31mError: Downloaded file is too small (<10KB, actual: $${FILESIZE} bytes)\x1b[0m"; \
		rm -f "$${TMPF}"; \
		exit 1; \
	fi; \
	echo "\x1b[33mSigning with key $$KEY_FILE\x1b0m"; \
	echo; \
	SIGNATURE="$$(openssl dgst -sha512 -sign "$$KEY_FILE" "$${TMPF}" | openssl base64 | tr -d '\n')"; \
	rm -f "$${TMPF}"; \
	echo "\x1b[32mReleasing to Nextcloud App Store...\x1b[0m"; \
	RESPONSE="$$(mktemp)"; \
	HTTP_CODE=$$(curl -s -w "%{http_code}" -o "$${RESPONSE}" -X POST \
	  -H "Authorization: Token $$NEXTCLOUD_API_TOKEN" \
	  -H "Content-Type: application/json" \
	  -d "{\"download\":\"$${DOWNLOAD_URL}\", \"signature\":\"$${SIGNATURE}\"}" \
	  https://apps.nextcloud.com/api/v1/apps/releases); \
	cat "$$RESPONSE"; echo; \
	if [ "$$HTTP_CODE" = "400" ]; then \
		echo "\x1b[31m❌ Error 400: Invalid data, app too large, signature/cert issue, or not registered\x1b[0m"; exit 1; \
	elif [ "$$HTTP_CODE" = "401" ]; then \
		echo "\x1b[31m❌ Error 401: Not authenticated\x1b[0m"; exit 1; \
	elif [ "$$HTTP_CODE" = "403" ]; then \
		echo "\x1b[31m❌ Error 403: Not authorized\x1b[0m"; exit 1; \
	elif [ "$$HTTP_CODE" -ge 300 ]; then \
		echo "\x1b[31m❌ Unexpected error (HTTP $$HTTP_CODE)\x1b[0m"; exit 1; \
	fi; \
	rm -f "$$RESPONSE"; \
	echo "\x1b[32m🎉 Release successful!\x1b[0m";
