# demo-scan-ballerina

[![Scan Ballerina](https://github.com/CharanaManawathilake/demo-scan-ballerina/actions/workflows/scan.yml/badge.svg?branch=main)](https://github.com/CharanaManawathilake/demo-scan-ballerina/actions/workflows/scan.yml)

A demo of the [scan-ballerina](https://github.com/ballerina-platform/scan-ballerina) action. It runs `bal scan` on an order service for an online store and sends the findings to GitHub code scanning and SonarQube.

## The order service

[`orders`](orders) is a Ballerina HTTP service at `/orders` on port 9090:

| File | What it does |
| --- | --- |
| [`service.bal`](orders/service.bal) | The HTTP resources: get and create an order, and refund one |
| [`auth.bal`](orders/auth.bal) | Validates customer JWTs |
| [`payments.bal`](orders/payments.bal) | Encrypts card numbers, hashes passwords and builds refund references |
| [`pricing.bal`](orders/pricing.bal) | Order totals and quantity parsing |
| [`logging.bal`](orders/logging.bal) | Sends the log to a file |
| [`db.bal`](orders/db.bal) | An in-memory order store |
| [`types.bal`](orders/types.bal) | The order, new order and refund records |

## The findings

The baseline, kept as `demo-base`, has five findings, each used by one demo, so every other alert in **Security > Code scanning** comes from a demo and is easy to tell apart. The demos merged into `main` have since fixed `crypto:2`, removed `encryptCardNumber` and added `compressLog`:

| File | Rule | Issue | State in the baseline |
| --- | --- | --- | --- |
| `auth.bal` | `ballerina/jwt:5` | Customer tokens are validated with a clock skew of one hour | Open |
| `logging.bal` | `ballerina/log:2` | The log file is written to `/tmp` | Open |
| `payments.bal` | `ballerina/crypto:2` | Passwords are hashed with a BCrypt work factor of 4 | Open |
| `payments.bal` | `ballerina/crypto:1` | Card numbers are encrypted with AES in ECB mode | Suppressed with `@scan:Suppress`, so its alert is dismissed as *won't fix* |
| `pricing.bal` | `ballerina:1` | `checkpanic` instead of `check` in `parseQuantity` | Suppressed, so its alert is dismissed as *won't fix* |

## GitHub code scanning

[`.github/workflows/scan.yml`](.github/workflows/scan.yml) runs on every push to `main` and `demo-base` and every pull request to them, and can be run by hand from the **Actions** tab. One job scans `orders` with the category `orders`:

| Input | Value | Effect |
| --- | --- | --- |
| `platforms` | `github-code-scanning` | Uploads the findings to GitHub code scanning |
| `annotations` | `false` | No workflow annotations, so each finding appears once, as a code scanning alert |
| `artifacts` | `true` | Saves the SARIF file as an artifact |
| `job-summary` | `true` | Writes the high, medium and low counts to the job summary |
| `exclude-tests` | `true` | Drops findings in `tests/` |
| `pr-comment` | `true` | Posts the reason of each suppressed finding a pull request adds, as a reply to code scanning's comment on its alert, and comments at each `@scan:Suppress` the pull request adds or removes for findings already on `main` |
| `fail-on-severity` | `high` | Counts the high findings |
| `fail-on-count` | `6` | Fails the step when 6 or more high findings are counted |

The findings on `main` are under **Security > Code scanning**.

### Gating

The two kinds of gate count different findings:

| Gate | Runs on | Counts | Result |
| --- | --- | --- | --- |
| `fail-on-severity` and `fail-on-count` in the action | `main`, `demo-base` and pull requests | Every finding in the package that is not suppressed | 0.11.1 reports no high findings, so **Scan order service** passes |
| Code scanning and the **Block new code scanning alerts** ruleset, on `main` and `demo-base` | Pull requests | Only the findings that are new compared with the base branch, in code the pull request changes | The **Ballerina Scan Tool** check passes either way, and its title gives the number of new alerts. Any new alert blocks the merge, until it is dismissed. Existing alerts on the base branch do not |

The ruleset also needs code scanning results for every pull request, so a pull request that does not upload its findings cannot be merged.

### Demo pull requests to `demo-base`

`main` keeps changing, so these pull requests target `demo-base`, a fixed copy of the baseline that is scanned on every push like `main`, and that the ruleset covers too. They stay open to show each case:

| Pull request | Change | Ballerina Scan Tool | What the pull request shows | Merge |
| --- | --- | --- | --- | --- |
| [#57](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/57) `demo-1` | New findings in `loyalty.bal`, one suppressed, shown as annotations and not uploaded | No results | Annotations for the findings, and a warning at the added `@scan:Suppress`. The suppressed `ledgerPoints` gets a comment of its own from the action, with the finding's severity, rule and message and the reason | Blocked, waiting for code scanning results |
| [#58](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/58) `demo-2` | Lets customers cancel an order, with no new findings | No new alerts | Nothing | Allowed |
| [#59](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/59) `demo-3` | New findings in `webhooks.bal`, one of them suppressed | 3 new alerts | Code scanning comments #79, #80 and #81. The action replies to #80, the suppressed one, with its reason, and warns at the added `@scan:Suppress` | Blocked |
| [#60](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/60) `demo-4` | New findings in `rewards.bal`, all suppressed | 2 new alerts | Code scanning comments #82 and #83, and the action replies to each with its reason, and warns at both added annotations | Blocked until both alerts are dismissed |
| [#61](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/61) `demo-5` | Suppresses `jwt:5` (#77), already open on the base branch | No new alerts | No new alert, as #77 is not new. The action warns at the added `@scan:Suppress` and comments at it, "Suppression added", with the rule it takes out of the gate and the reason, since otherwise nothing would show it | Allowed. Its alert would be dismissed only by a merge to `main` |
| [#62](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/62) `demo-6` | Removes the suppression of `parseQuantity` (#74) | No new alerts | A warning at the removed `@scan:Suppress` that its findings are reported again and their alerts stay dismissed until the merge, and a comment on the deleted line, "Suppression removed", with the rule that was suppressed and the reason | Allowed |

### Demo pull requests to `main`

These pull requests show what each change does to the alerts in **Security > Code scanning**. Each has an issue that gave the expected result and records what happened. They were merged one at a time, each after the scan of the one before:

| Issue | Pull request | Change | What the pull request showed | Alert after the merge |
| --- | --- | --- | --- | --- |
| [#63](https://github.com/CharanaManawathilake/demo-scan-ballerina/issues/63) | [#68](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/68) | Suppresses `log:2` (#78), open on `main` | Nothing | #78 closed, dismissed as *won't fix* with the reason |
| [#64](https://github.com/CharanaManawathilake/demo-scan-ballerina/issues/64) | [#72](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/72) | Removes that suppression again | A warning that the finding is no longer suppressed | #78 open again |
| [#65](https://github.com/CharanaManawathilake/demo-scan-ballerina/issues/65) | [#69](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/69) | Fixes `crypto:2` (#76) in `hashCustomerPassword` | Nothing | #76 closed as fixed |
| [#66](https://github.com/CharanaManawathilake/demo-scan-ballerina/issues/66) | [#70](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/70) | Removes `encryptCardNumber`, whose `crypto:1` finding (#75) is suppressed | Nothing | #75 closed as fixed, no longer *won't fix* |
| [#67](https://github.com/CharanaManawathilake/demo-scan-ballerina/issues/67) | [#71](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/71) | Adds `compressLog`, suppressed from the start | 1 new alert, #84, with the reason as a reply. Blocked until #84 was dismissed by hand | #84 stays closed, and its comment becomes the suppression's reason |

### Suppressed findings in pull requests

A finding accepted in the source with `@scan:Suppress` is left out of the counts and the gate, but it is still uploaded to code scanning, and its alert is only dismissed automatically on `main`. So in a pull request:

- A finding the pull request newly suppresses is a new alert. Code scanning comments on it, and the ruleset blocks the merge until someone allowed to dismiss alerts dismisses it ([#60](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/60), [#71](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/71)).
- The action replies to code scanning's comment with the reason given in the annotation, so the reviewer can decide. A finding code scanning does not comment, such as one in a run that does not upload, gets a comment of its own at its line ([#57](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/57)). Pushing again edits that comment rather than adding another.
- The action warns at each `@scan:Suppress` the pull request adds or removes, read from the diff, so also in runs for forks. A moved annotation, or one whose reason alone changes, is neither.
- When the annotation's findings are already on `main`, code scanning shows nothing for them, so the action also comments at the annotation, on the deleted line for a removed one, giving their rules and the reason. Later runs edit that comment rather than add another.
- Suppressing a finding already on the base branch adds no alert, so the warning and the comment at the annotation are what show it ([#61](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/61)), and removing a suppression shows a warning and a comment at the deleted line ([#62](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/62)).
- Suppressed findings already on `main` are dismissed there, so they are not shown again.

The job needs `pull-requests: write` to comment. Runs for pull requests from forks have a read-only token, so they cannot comment, but their alerts are still shown.

Code scanning is free for public repositories. Private repositories need GitHub Advanced Security. The job needs `security-events: write` to upload and `actions: read` for the upload to read the workflow run.

## SonarQube

[`.github/workflows/sonarqube.yml`](.github/workflows/sonarqube.yml) runs on every push to `main`. One job scans `orders` once and sends the findings to the SonarQube project `demo-scan-ballerina-order-service`.

It needs the repository variable `SONAR_HOST_URL` (an `https` URL) and the repository secret `SONAR_TOKEN`. The SonarQube server needs the Ballerina language plugin.

## Running the scan locally

```sh
cd orders
bal scan --format=sarif
```

The report is written to `target/report/scan_results.sarif`. The service uses Ballerina 2201.13.5.
