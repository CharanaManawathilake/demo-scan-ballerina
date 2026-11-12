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

The service is kept to five findings, each used by one demo, so every other alert in **Security > Code scanning** comes from a demo and is easy to tell apart:

| File | Rule | Issue | State on `main` |
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
| `pr-comment` | `true` | Posts the reason of each suppressed finding a pull request adds, as a reply to code scanning's comment on its alert |
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

`main` keeps changing, so these pull requests target `demo-base`, a fixed copy of `main` that is scanned on every push like `main`, and that the ruleset covers too. They stay open to show each case:

| Pull request | Change | Expected in the pull request | Merge |
| --- | --- | --- | --- |
| `demo-1` | New findings in `loyalty.bal`, one suppressed, shown as annotations and not uploaded | Annotations for the findings. The suppressed one gets a comment of its own from the action, with the finding's severity, rule and message and the reason | Blocked, waiting for code scanning results |
| `demo-2` | Lets customers cancel an order, with no new findings | Nothing | Allowed |
| `demo-3` | New findings in `webhooks.bal`, one of them suppressed | Code scanning comments each new alert. The action replies to the suppressed one with its reason | Blocked |
| `demo-4` | New findings, all suppressed | Code scanning comments both, and the action replies to each with its reason | Blocked until both alerts are dismissed |
| `demo-5` | Suppresses `jwt:5`, already open on the base branch | Nothing: the alert is not new, and the finding's line is not one the pull request adds | Allowed. Its alert would be dismissed only by a merge to `main` |
| `demo-6` | Removes the suppression of `parseQuantity` | A warning at the finding that it is no longer suppressed, and that its alert stays dismissed on `main` until the change is merged there | Allowed |

### Demo pull requests to `main`

These pull requests show what each change does to the alerts in **Security > Code scanning** once merged. Each has an issue that gives the expected result, and they are merged one at a time, as each merge changes the alerts of `main`:

| Branch | Change | Expected in the pull request | Alert after the merge |
| --- | --- | --- | --- |
| `main-suppress-existing` | Suppresses `log:2`, open on `main` | Nothing | Closed, dismissed as *won't fix* with the reason |
| `main-remove-suppression` | Removes that suppression again | A warning that the finding is no longer suppressed | Open again |
| `main-fix-finding` | Fixes `crypto:2` in `hashCustomerPassword` | Nothing | Closed as fixed |
| `main-remove-suppressed-code` | Removes `encryptCardNumber`, whose `crypto:1` finding is suppressed | Nothing | Closed as fixed, no longer *won't fix* |
| `main-new-suppressed` | Adds `compressLog`, suppressed from the start | 1 new alert, with the reason as a reply. Blocked until it is dismissed | Stays closed, and its comment becomes the suppression's reason |

### Suppressed findings in pull requests

A finding accepted in the source with `@scan:Suppress` is left out of the counts and the gate, but it is still uploaded to code scanning, and its alert is only dismissed automatically on `main`. So in a pull request:

- A finding the pull request newly suppresses is a new alert. Code scanning comments on it, and the ruleset blocks the merge until someone allowed to dismiss alerts dismisses it (`demo-4`, `main-new-suppressed`).
- The action replies to code scanning's comment with the reason given in the annotation, so the reviewer can decide. A finding code scanning does not comment, such as one in a run that does not upload, gets a comment of its own at its line (`demo-1`). Pushing again edits that comment rather than adding another.
- Suppressing a finding already on the base branch shows nothing (`demo-5`), and removing a suppression shows a warning (`demo-6`).
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
