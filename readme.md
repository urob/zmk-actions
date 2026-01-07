# ZMK Actions

This repository contains several Github actions for ZMK users and developers. It also contains a nix
shell that can be used as drop-in replacement for the ZMK Docker container, both locally and in
Github actions.

## Actions

Actions for building ZMK firmware:

- `build-user-config`: Drop-in replacement for the official docker-based build workflow.

Actions for ZMK module developers:

- `upgrade-zmk`: Check for new ZMK releases and create matching module PRs
   dependencies.
- `run-tests`: Run automated module tests on pull requests.
- `upgrade-module`: Create module versions to match ZMK version on merge.

Actions with special purposes and unlikely to be used directly:

- `setup-sdk`: Set up nix shell with Zephyr SDK, `west` and other build dependencies.
- `setup-zmk`: Create ZMK workspace with all required west modules.
- `test`: Low-level action supporting `run-tests`.

## Nix shell

Todo: document `flake.nix` and add template for local usage.

## Maintaining ZMK modules

The actions for developers are designed around automated module testing leveraging the same
`native_posix`-based test environment used upstream. To make this work, the test environment is
tied to a specific ZMK release.

Whenever a new ZMK release is detected, the `upgrade-zmk` workflow creates a PR to bump the ZMK
release used by the testing environment and then triggers the `run-tests` workflow using the new ZMK
release. The outcomes of the tests are attached to the PR.

If all tests pass and the PR is merged, the `upgrade-module` workflow is triggered which adds a tag
to the `head` of the module repository matching the ZMK release. It further adds or moves
corresponding `major` and `minor` version tags to the same commit.

## Usage

### 1. Add tests to your module

By default, the `run-tests` workflow looks for tests in the `tests` directory. All tests are
expected to follow the naming, design and syntax of the
[ZMK test suite](https://zmk.dev/docs/development/local-toolchain/tests).

In addition, the `tests` directory should contain a `west.yml` file that defines the current test
environment. If the only module dependency is ZMK, the `west.yml` file should look like this:

```yaml
manifest:
  remotes:
    - name: zmkfirmware
      url-base: https://github.com/zmkfirmware
  projects:
    - name: zmk
      remote: zmkfirmware
      revision: v0.1.0 # This will be maintained by the upgrade-zmk workflow
      import: app/west.yml
  self:
    path: tests
```

For an example, see the [`tests`](https://github.com/urob/zmk-leader-key/tree/main/tests) directory
of the `urob/zmk-leader-key` module.

### 2. Add workflows to your repository

In most cases, it should suffice to copy the contents of
[`templates`](https://github.com/urob/zmk-actions/tree/main/templates) to your repository.
The following provides a more detailed explanation of each workflow recipe.

#### 2a/ `upgrade-zmk`

It is recommended to configure `upgrade-zmk` as a cron job. The following will set up a daily check
for new ZMK releases:

```yaml
name: Check for new ZMK releases
on:
  workflow_dispatch:
  schedule:
    - cron: "0 22 * * *" # Run daily at 22:00 UTC
jobs:
  upgrade-zmk:
    uses: urob/zmk-actions/.github/workflows/upgrade-zmk.yml@v8.0.1
    permissions:
      contents: write
    secrets:
      # >>> Add a Personal Access Token with write access to pull requests here <<<
      token: ${{ secrets.ZMK_MODULES_ACTIONS }}
```

The workflow supports the following optional input parameters:

- `upstream` - The upstream ZMK repository to check for new releases. Defaults to `zmkfirmware/zmk`.
- `west_path` - The path to the `west` manifest that defines the test environment. Defaults to
  `tests/west.yml`.
- `pr_branch` - The branch to create PRs in. Defaults to `upgrade-zmk`.
- `pr_label` - A label to add to PRs. Defaults to none.

#### 2b/ `run-tests`

At a minimum, `run-tests` should be triggered on pull requests to the `tests` directory. The
following sets up additional triggers for other pull requests and pushes:

```yaml
name: Run tests
on:
  workflow_dispatch:
  push:
    paths:
      - "dts/**"
      - "include/**"
      - "src/**"
      - "tests/**"
  pull_request:
    paths:
      - "dts/**"
      - "include/**"
      - "src/**"
      - "tests/**"
jobs:
  test:
    uses: urob/zmk-actions/.github/workflows/run-tests.yml@v8.0.1
```

The workflow supports the following optional input parameters:

- `tests_path` - The path to the tests directory. Defaults to `tests`.

#### 2c/ `upgrade-module`

`upgrade-module` should be triggered on pull request merges to your `main` branch. The action will
only create a new release if the pull request title starts with `Bump ZMK`. So this is safe to run
on all merges.

```yaml
name: Release module version
on:
  pull_request:
    types:
      - closed
    branches:
      - main
jobs:
  release:
    uses: urob/zmk-actions/.github/workflows/upgrade-module.yml@v8.0.1
    permissions:
      contents: write
```

The workflow supports the following optional input parameters:

- `release_branch` - The branch to create the release from. Defaults to `main`.

### 3. Create a Personal Access Token

The `upgrade-zmk` workflow requires a Personal Access Token with write access to pull requests.[^1]
The following steps outline how to create the token:

1. Go to your GitHub account settings.
2. Create a new Personal Access token under Developer settings. (The name doesn't matter.)
3. Configure the token to have the following repository permissions:
   - Read access to metadata
   - Write access to pull requests
4. Copy the token and store it in a secure location.
5. Go to the repository where you want to use the token.
6. Go to 'Action secrets and variables' in the repository settings.
7. Add a new repository secret with the same name as passed to `upgrade-zmk` in step 2a/ above.
8. Set the secret value to the token you created in steps 1-4.

[^1]:
    This is so that the `upgrade-zmk` workflow can trigger the `run-tests` workflow. See
    [here](https://docs.github.com/en/actions/writing-workflows/choosing-when-your-workflow-runs/triggering-a-workflow#triggering-a-workflow-from-a-workflow)
    for a full explanation.
