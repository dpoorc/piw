# Publishing

Considerations for making the harness public. This is a checklist, not a plan.

## Before publishing

### README

The repository root has a `README.md` with the quick start. Keep it short:
what piw is, the prerequisites, the install steps, and a link to the docs.

### LICENSE

The repository is GPLv3. See [LICENSE](../LICENSE).

### CONTRIBUTING

Document the alignment-before-action workflow. A contributor should
understand the proposal step before opening a pull request that skips it.

### CI

`.github/workflows/ci.yml` runs shellcheck and the hermetic test suite. The
suite needs no Docker daemon, because it drives `piw` against a stub `docker`.
The only external dependency is `yq`, which the catalog test uses.

### Secrets template

`.env.example` lists the API keys a user might need. Keep it current with the
providers that `seed/models.json` refers to.

## Audience

piw is not a beginner tool. The user must:

- Have Docker installed and running.
- Have at least one API key for pi.
- Be comfortable editing JSON and text manifests.

The target reader is a power user of pi who wants Docker isolation,
configurable permissions, and a composable tool environment.

## Friction points

| Friction | Mitigation |
|----------|------------|
| Docker is required | State it in the README. `piw doctor` diagnoses the setup. |
| API key setup is manual | The README shows the `.env.example` copy step. |
| The agent proposes before it acts | Frame this as a feature in the README. |
| No browser in the container | Document the web-search fallback. |
| Self-hosting is confusing | State that the workspace is independent from the harness. |

## Verification coverage

Be honest about what is verified and what is not:

- The hermetic suite covers argument parsing, image tags, mounts,
  environment, and the container command. It runs without Docker.
- The suite does not run a real container. A build and a launch are verified
  by hand on a Docker host.
- The permission modes are configuration. The suite does not assert their
  effect, because the user owns the configuration.

## Relationship to pi

piw wraps pi. It is a community wrapper, not an official product. State this
in the README, so the support scope is clear.
