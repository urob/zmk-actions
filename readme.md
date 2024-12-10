# ZMK-MODULES-ACTIONS

This repository contains GitHub Actions workflows for maintaining ZMK modules. The workflows are
designed to work in sequence:

1. `upgrade-zmk.yml` - Periodically check for new ZMK releases and create PRs to bump module
   dependencies.
2. `run-tests.yml` - Run automated module tests on pull requests.
3. `upgrade-module.yml` - Automatically bump module version to match ZMK version on merge.

## Usage

### Create a Personal Access Token

The `upgrade-zmk` workflow requires setting up a Personal Access Token.[^1]

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

### Add workflows to your repository

TODO: Paste dispatch workflows here

### Configuration

TODO: Document custom workflow parameters

[^1]:
    This is so that the `upgrade-zmk` workflow can trigger the `run-tests` workflow. See
    [here](https://docs.github.com/en/actions/writing-workflows/choosing-when-your-workflow-runs/triggering-a-workflow#triggering-a-workflow-from-a-workflow)
    for a full explanation.
