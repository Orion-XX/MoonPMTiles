# Contributing to MoonPMTiles

## Before changing code

Read `AGENTS.md`, the current task card in `docs/04_TASK_BREAKDOWN.md`, and its dependencies. Work on a new branch for each task. Do not overwrite unrelated working tree changes or commit internal planning material under `docs/`, `development/`, `research/`, or `submission/` unless the task explicitly allows it.

## Validation

Run the commands required by the task card:

```powershell
moon fmt --check
moon check --deny-warn --target all
moon test --deny-warn --target all
moon info
```

Record target-specific results and distinguish verified, partially verified, unverified, and blocked behavior. Do not claim a platform is supported solely because another target compiled.

## Commits and pull requests

Use focused commits with the task identifier in the subject, for example:

```text
feat(codec): validate PMTiles headers (P-02)
```

All project commits and pull requests must use:

```text
OrionX <213938578+Orion-XX@users.noreply.github.com>
```

Pull requests should state scope, files changed, complete commands, target results, test counts, fixture/dependency provenance, known failures, and remaining risks.
