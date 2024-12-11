# ZMK-MODULES-ACTIONS

This repository contains GitHub Actions workflows for automatically testing ZMK modules and
synchronizing releases with ZMK. The workflows are designed to work in sequence:

1. `upgrade-zmk.yml` - Periodically check for new ZMK releases and create PRs to bump module
   dependencies.
2. `run-tests.yml` - Run automated module tests on pull requests.
3. `upgrade-module.yml` - Automatically bump module version to match ZMK version on merge.

## How it works

These workflows are designed around automated module testing leveraging the same
`native_posix_64`-based test environment used upstream. To make this work, the test environment is
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

In most cases, it should suffice to copy the `zmk-leader-key`'s contents of
[`.github/workflows`](https://github.com/urob/zmk-leader-key/tree/main/.github/workflows) to your
repository. The following provides some additional pointers.

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
  build:
    uses: urob/zmk-modules-actions/.github/workflows/upgrade-zmk.yml@main
    permissions:
      contents: write
    secrets: inherit
```

The workflow supports the following optional input parameters:

- `upstream` - The upstream ZMK repository to check for new releases. Defaults to `zmkfirmware/zmk`.
- `west_path` - The path to the `west` manifest that defines the test environment. Defaults to `tests/west.yml`.
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
      - "tests/**"
      - "src/**"
      - "include/**"
  pull_request:
    paths:
      - "tests/**"
      - "src/**"
      - "include/**"
jobs:
  build:
    uses: urob/zmk-modules-actions/.github/workflows/run-tests.yml@main
```

The workflow supports the following optional input parameters:

- `tests_path` - The path to the tests directory. Defaults to `tests`.

#### 2c/ `upgrade-module`

`upgrade-module` should be triggered on pull request merges to your `main` branch. The action will
only create a new release if the pull request title starts with `Bump ZMK`. So this is safe to run
on all merges.

```yaml
name: Create new module release
on:
  pull_request:
    types:
      - closed
    branches:
      - main
jobs:
  build:
    permissions:
      contents: write
    uses: urob/zmk-modules-actions/.github/workflows/upgrade-module.yml@main
```

The workflow supports the following optional input parameters:

- `release_branch` - The branch to create the release from. Defaults to `main`.

### 3. Create a Personal Access Token

The `upgrade-zmk` workflow requires a Personal Access Token with write access to actions and pull
requests.[^1] The token should be stored as a repository secret named `ACTIONS_UPGRADE_ZMK`. The
following steps outline how to create the token:

1. Go to your GitHub account settings.
2. Create a new Personal Access token under Developer settings.
3. Configure the token to have the following repository permissions:
   - Read access to metadata
   - Read & write access to actions and pull requests
4. Copy the token and store it in a secure location.
5. Go to the repository where you want to use the token.
6. Go to 'Action secrets and variables' in the repository settings.
7. Add a new repository secret with the name `ACTIONS_UPGRADE_ZMK`.
8. Set the secret value to the token you created in steps 1-4.

[^1]:
    This is so that the `upgrade-zmk` workflow can trigger the `run-tests` workflow. See
    [here](https://docs.github.com/en/actions/writing-workflows/choosing-when-your-workflow-runs/triggering-a-workflow#triggering-a-workflow-from-a-workflow)
    for a full explanation.
