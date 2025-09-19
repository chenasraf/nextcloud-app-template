<!--
SPDX-FileCopyrightText: Your Name <your@email.com>
SPDX-License-Identifier: CC0-1.0
-->

# Nextcloud App Template

This is a starter template for a Nextcloud app, using Vue 3 with Vite as frontend.

It also has a convenient file generator for when you will be developing your app.

## How to use this template

At the top of the GitHub page for this repository, click "Use this template" to create a copy of
this repository.

Once you have it cloned on your machine:

1. Run `./rename-template.sh` to do a mass renaming of all the relevant files to match your app name
   and your user/full name. They will be asked as input when you run the script.
1. Run `make` - this will trigger the initial build, download all dependencies and make other
   preparations as necessary.

## Makefile

There is a robust Makefile in the project which should give you everything you need in order to
develop &amp; release your app.

Below is a rundown of the different targets you can run:

| Command             | What it does                                                                                                                       | When to use it                        | Notes                                                                  |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------- | ---------------------------------------------------------------------- |
| `make`              | Alias for `make build`.                                                                                                            | Anytime; default target.              | Same as `make build`.                                                  |
| `make build`        | Installs PHP deps (if `composer.json` exists) and JS deps (if `package.json` or `js/package.json` exists), then runs the JS build. | First run; after pulling changes; CI. | Skips steps that don’t apply (no `composer.json` / no `package.json`). |
| `make composer`     | Installs Composer deps. If Composer isn’t installed, fetches a local `composer.phar`.                                              | When PHP deps changed.                | Skips if `vendor/` already exists.                                     |
| `make pnpm`         | `pnpm install --frozen-lockfile` then run build. Uses root `package.json` if present, else `js/`.                                  | When JS deps or build changed.        | Requires `pnpm`.                                                       |
| `make clean`        | Removes `build/` artifacts.                                                                                                        | Before re-packaging; to start fresh.  | Keeps dependencies.                                                    |
| `make distclean`    | `clean` + removes `vendor/`, `node_modules/`, `js/vendor/`, `js/node_modules/`.                                                    | Nuke-from-orbit cleanup.              | You’ll need to re-install deps.                                        |
| `make dist`         | Runs `make source` and `make appstore`.                                                                                            | Release prep; CI packaging.           | Produces both tarballs.                                                |
| `make source`       | Builds a **source** tarball at `build/artifacts/source/<app>.tar.gz`.                                                              | Sharing source-only bundle.           | Excludes tests, logs, node_modules, etc.                               |
| `make appstore`     | Builds an **App Store–ready** tarball at `build/artifacts/appstore/<app>.tar.gz`.                                                  | Upload to Nextcloud App Store.        | Aggressively excludes dev/test files & dotfiles.                       |
| `make test`         | Runs PHP unit tests (`tests/phpunit.xml` and optional `tests/phpunit.integration.xml`).                                            | CI or local test run.                 | Ensures Composer deps first.                                           |
| `make lint`         | Lints JS (`pnpm lint`) and PHP (`composer run lint` via local `composer.phar` if needed).                                          | Pre-commit checks.                    | Requires corresponding scripts.                                        |
| `make php-cs-fixer` | Fixes **staged** PHP files with PHP-CS-Fixer (after `php -l`).                                                                     | Before committing PHP changes.        | Operates on files staged in Git.                                       |
| `make format`       | Formats JS (`pnpm format`) and PHP (`composer run cs:fix`).                                                                        | Enforce code style.                   | Requires those scripts in composer/package.json.                       |
| `make openapi`      | Generates OpenAPI JSON via composer script `openapi`.                                                                              | Refresh API docs.                     | Output: `build/openapi/openapi.json`.                                  |
| `make sign`         | Downloads the GitHub release tarball for the version in `version.txt` and prints a base64 SHA-512 signature.                       | Manual signing for App Store.         | Needs private key at `~/.nextcloud/certificates/<app>.key`.            |
| `make release`      | Uploads the signed release to the Nextcloud App Store.                                                                             | Final publish step.                   | Needs `NEXTCLOUD_API_TOKEN` env var; prompts if missing.               |

### Quick workflows

**Fresh setup / development**

```bash
pnpm --version   # ensure pnpm is installed
make build       # install PHP+JS deps and build
make test        # run PHP tests
make lint        # lint JS + PHP
```

**Package for release**

```bash
make dist        # builds both source + appstore tarballs
```

**Sign and publish to App Store**

```bash
# Ensure version.txt is set, and your key exists at ~/.nextcloud/certificates/<app>.key
make sign        # prints signature for the GitHub tarball
export NEXTCLOUD_API_TOKEN=...   # or let the target prompt you
make release
```

> Prerequisites: `make`, `curl`, `tar`, `pnpm`, and (optionally) `composer`. If Composer isn’t
> installed, the Makefile auto-downloads a local `composer.phar`.

## NPM (package.json)

Run with `pnpm <script>` (or `npm run <script>` / `yarn <script>` if you prefer).

| Script         | What it does                                                                         | When to use it                                                    | Notes                                                                                                                                         |
| -------------- | ------------------------------------------------------------------------------------ | ----------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `pnpm dev`     | Runs `vite build --watch`.                                                           | Local dev where you want incremental rebuilds written to `dist/`. | This is a **watching build**, not a dev server. It continuously rebuilds on file changes. Pair it with Nextcloud serving the compiled assets. |
| `pnpm build`   | Type-checks with `vue-tsc -b` and then does a full `vite build`.                     | CI, release builds, or when you want a clean production bundle.   | `vue-tsc -b` runs TypeScript project references/build mode, catching TS errors beyond ESLint.                                                 |
| `pnpm lint`    | Lints the `src/` directory using ESLint.                                             | Quick checks before committing or in CI.                          | Respects your `.eslintrc*` config. No auto-fix.                                                                                               |
| `pnpm format`  | Auto-fixes ESLint issues in `src/` and then runs Prettier on `src/` and `README.md`. | Enforce consistent style automatically.                           | Safe to run often; keeps diffs clean.                                                                                                         |
| `pnpm prepare` | Runs `husky` installation hook.                                                      | After `pnpm install` (automatically).                             | Ensures Git hooks (like pre-commit linting) are installed.                                                                                    |
| `pnpm gen`     | Generates scaffolding for various templates (both PHP and TS)                        | Anytime you want to easily create new files from templates.       | See [below](#Scaffolding)                                                                                                                     |

## Common workflows

**While developing (continuous build output):**

```bash
pnpm dev
# Edit files → Vite rebuilds to dist/ automatically.
```

**Before pushing a branch (runs automatically using commit hooks):**

```bash
pnpm lint
pnpm build
```

**Fix style issues quickly:**

```bash
pnpm format
```

**Fresh clone:**

```bash
pnpm install
# husky installs via "prepare"
pnpm build
```

### Scaffolding

Generate boilerplate for common app pieces with:

```bash
pnpm gen <type> [name]
```

- **`name` is required** for every type **except** `migration`.
- Files are created from templates in `gen/<type>` and written to the configured output directory.
  Feel free to modify/remove any of these templates or add new ones.
- Generators never create subfolders (they write directly into the output path).

#### Available generators

| Type          | Purpose                                   | Output directory | Name required? | Template folder   | Notes                                             |
| ------------- | ----------------------------------------- | ---------------- | -------------- | ----------------- | ------------------------------------------------- |
| `component`   | Vue single-file component for reusable UI | `src/components` | ✅             | `gen/component`   | For user-facing building blocks.                  |
| `page`        | Vue page / route view                     | `src/pages`      | ✅             | `gen/page`        | Pair with your router.                            |
| `api`         | PHP controller (API endpoint)             | `lib/Controller` | ✅             | `gen/api`         | PSR-4 namespace: `OCA\<App>\Controller`.          |
| `service`     | PHP service class                         | `lib/Service`    | ✅             | `gen/service`     | Business logic; DI-friendly.                      |
| `util`        | PHP utility/helper                        | `lib/Util`       | ✅             | `gen/util`        | Pure helpers / small utilities.                   |
| `model`       | PHP DB model / entity                     | `lib/Db`         | ✅             | `gen/model`       | Pair with migrations.                             |
| `command`     | Nextcloud OCC console command             | `lib/Command`    | ✅             | `gen/command`     | Shows up in `occ`.                                |
| `task-queued` | Queued background job                     | `lib/Cron`       | ✅             | `gen/task-queued` | Extend queued job base.                           |
| `task-timed`  | Timed background job (cron)               | `lib/Cron`       | ✅             | `gen/task-timed`  | Scheduled execution.                              |
| `migration`   | Database migration                        | `lib/Migration`  | ❌             | `gen/migration`   | Auto-numbers version; injects `version` and `dt`. |

##### How migrations are numbered

The scaffolder looks at `lib/Migration`, finds the latest `VersionNNNN...` file, and **increments**
it for you. It also injects:

- `version` — the next numeric version
- `dt` — a timestamp like `YYYYMMDDHHmmss` (via `date-fns`)

You don’t pass a name for migrations.

#### Examples

Create a Vue component:

```bash
pnpm gen component UserListItem
# → src/components/UserListItem.vue
```

Create a Vue page:

```bash
pnpm gen page Settings
# → src/pages/Settings.vue
```

Create an API controller:

```bash
pnpm gen api Users
# → lib/Controller/UsersController.php
```

Create a service:

```bash
pnpm gen service MyService
# → lib/Service/MyService.php
```

Create a queued job:

```bash
pnpm gen task-queued UpdateUsers
# → lib/Cron/UpdateUsers.php
```

Create a migration (no name):

```bash
pnpm gen migration
# → lib/Migration/Version{NEXT}.php   (with injected {version} and {dt})
```

#### Tips & gotchas

- **Router pages:** After `pnpm gen page <Name>`, add the route in your router
  (`src/router/index.ts`) and import the file.
- **Cron vs queued:** Use `task-timed` for scheduled runs, `task-queued` for background work
  enqueued by events or controllers.

## Project layout

```
.
├─ appinfo/                     # App metadata & registration (info.xml, routes.php, app.php)
├─ lib/                         # PHP backend code (PSR-4: OCA\<App>\…)
│  ├─ Controller/               # OCS/HTTP controllers (API endpoints)
│  ├─ Service/                  # Business logic & integrations
│  ├─ Db/                       # Entities / mappers
│  ├─ Migration/                # Database migrations (Version*.php)
│  ├─ Cron/                     # Timed/queued background jobs
│  ├─ Command/                  # occ console commands
│  └─ Util/                     # Small helpers
├─ src/                         # Frontend (Vue 3 + Vite + TS)
│  ├─ app.ts                    # ⚡ Loader for the **user-facing app** (loaded via templates/app.php)
│  ├─ settings.ts               # ⚙️ Loader for the **settings page** (loaded via templates/settings.php)
│  ├─ main.ts                   # (optional) main entry or shared bootstrap
│  ├─ components/               # Reusable UI components
│  ├─ pages/                    # Route views / pages (user-facing)
│  ├─ views/                    # Additional views (e.g., settings sub-pages)
│  ├─ router/                   # Vue Router setup
│  ├─ styles/                   # Global styles
│  └─ assets/                   # Static assets used by the frontend
├─ templates/                   # Server-rendered entry templates
│  ├─ app.php                   # Mounts the user-facing app bundle (uses dist output of src/app.ts)
│  └─ settings.php              # Mounts the settings bundle (uses dist output of src/settings.ts)
├─ l10n/                        # Translations (JSON/JS) for IL10N
├─ build/                       # Build artifacts & tools (created by Makefile)
│  ├─ artifacts/                # Packaged tarballs (source/appstore)
│  └─ tools/                    # composer.phar, etc.
├─ gen/                         # Scaffolding templates (used by `pnpm gen`)
│  ├─ component/ page/ api/ …   # See “Scaffolding” section
├─ dist/                        # Vite build output (bundled JS/CSS)
├─ tests/                       # PHPUnit configs & tests
├─ package.json                 # Frontend scripts (`pnpm build`, `pnpm dev`, etc.)
├─ composer.json                # PSR-4 autoload for PHP (e.g., "OCA\\<App>\\" : "lib/")
├─ Makefile                     # Build, lint, package, release
├─ version.txt                  # App version (used by sign/release targets)
└─ rename-template.sh           # One-time renamer script for template cloning
```

## Resources

- **Nextcloud app development**

  - [App dev guide](https://docs.nextcloud.com/server/latest/developer_manual/app/)
  - [OCS API](https://docs.nextcloud.com/server/latest/developer_manual/client_apis/OCS/index.html)
  - [Publishing to the App Store](https://docs.nextcloud.com/server/latest/developer_manual/app_publishing/index.html)
  - [App signing](https://docs.nextcloud.com/server/latest/developer_manual/app_publishing/signing.html)
  - [Server dev environment](https://docs.nextcloud.com/server/latest/developer_manual/general/devenv.html)

- **Nextcloud UI & components**

  - [nextcloud-vue (components)](https://github.com/nextcloud/nextcloud-vue)
  - [Component docs/storybook](https://nextcloud.github.io/nextcloud-vue/)

- **Frontend stack**

  - [Vue 3](https://vuejs.org/)
  - [Vue Router](https://router.vuejs.org/)
  - [Vite](https://vitejs.dev/guide/)
  - [pnpm](https://pnpm.io/)
  - [Axios](https://axios-http.com/)

- **Backend & tooling**

  - [Composer](https://getcomposer.org/doc/)
  - [PHP CS Fixer](https://github.com/PHP-CS-Fixer/PHP-CS-Fixer)
  - [ESLint](https://eslint.org/docs/latest/)
  - [Prettier](https://prettier.io/docs/en/)
  - [OpenAPI spec](https://spec.openapis.org/oas/latest.html)
  - [date-fns](https://date-fns.org/)
