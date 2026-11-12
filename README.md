# demo-scan-ballerina

[![Scan Ballerina](https://github.com/CharanaManawathilake/demo-scan-ballerina/actions/workflows/scan.yml/badge.svg?branch=main)](https://github.com/CharanaManawathilake/demo-scan-ballerina/actions/workflows/scan.yml)

A demo of the [scan-ballerina](https://github.com/ballerina-platform/scan-ballerina) action. It runs `bal scan` on an order service for an online store and sends the findings to GitHub code scanning and SonarQube.

## The order service

[`order-service`](order-service) is a Ballerina HTTP service at `/orders` on port 9090:

| File | What it does |
| --- | --- |
| [`service.bal`](order-service/service.bal) | The HTTP resources: orders, refunds, shipment tracking, checkout redirects, invoices and report exports |
| [`auth.bal`](order-service/auth.bal) | Validates customer and partner JWTs, and issues customer tokens |
| [`payments.bal`](order-service/payments.bal) | Encrypts card numbers and receipts, hashes passwords, verifies payment webhooks and sends refunds |
| [`pricing.bal`](order-service/pricing.bal) | Order totals, discounts and refund rules |
| [`reports.bal`](order-service/reports.bal) | Exports and archives reports with external commands |
| [`db.bal`](order-service/db.bal) | An in-memory order store |
| [`types.bal`](order-service/types.bal) | The order, new order and refund records |

The service has deliberate security issues and code smells, so the scan has something to report.

## The findings

The issues are listed below by the severity of their rule. `bal scan` 0.11.1, which the workflow uses, reports the high ones as medium, and has no rules `ballerina:13` and `ballerina:14`, so on `main` it reports 30 findings, 18 medium and 12 low, 3 of them suppressed with `@scan:Suppress`:

| File | Severity | Rule | Issue |
| --- | --- | --- | --- |
| `auth.bal` | High | `ballerina/jwt:1` | Customer tokens are issued with the `none` algorithm |
| `auth.bal` | High | `ballerina/jwt:2` | Customer tokens are validated without a signature configuration |
| `auth.bal` | High | `ballerina/jwt:6` | TLS validation is turned off for the partner JWKS endpoint |
| `auth.bal` | Medium | `ballerina/jwt:3` | Customer tokens are validated without checking the issuer and audience |
| `auth.bal` | Medium | `ballerina/jwt:4` | Customer tokens expire after 30 days |
| `auth.bal` | Medium | `ballerina/jwt:5` | A clock skew of one hour |
| `auth.bal` | Low | `ballerina/jwt:7` | A token is decoded without being verified |
| `auth.bal` | Low | `ballerina:3` | `issueToken` is public but not isolated |
| `payments.bal` | High | `ballerina/io:2` | The payment gateway key is printed to the console |
| `payments.bal` | Medium | `ballerina/crypto:1` | Card numbers are encrypted with AES in ECB mode |
| `payments.bal` | Medium | `ballerina/crypto:2` | Passwords are hashed with a BCrypt work factor of 4 |
| `payments.bal` | Medium | `ballerina/crypto:3` | Receipts are encrypted with a fixed AES-GCM initialization vector |
| `payments.bal` | Medium | `ballerina/log:1` | The payment gateway key is logged |
| `reports.bal` | High | `ballerina/os:3` | A report is generated through `sh -c` |
| `reports.bal` | High | `ballerina/os:4` | `sh` and `tar` are resolved through `PATH` (2 findings) |
| `reports.bal` | Medium | `ballerina/log:2` | The log file is written to `/tmp` |
| `service.bal` | Medium | `ballerina/http:1` | A `default` resource accepts every method and path |
| `service.bal` | Medium | `ballerina/http:2` | CORS allows every origin with credentials |
| `service.bal` | Medium | `ballerina/http:4` | Checkout redirects to a URL taken from the request |
| `pricing.bal` | Low | `ballerina:1` | `checkpanic` instead of `check` |
| `pricing.bal` | Low | `ballerina:2` | The `currency` parameter is not used |
| `pricing.bal` | Low | `ballerina:3` | `orderTotal` is public but not isolated |
| `pricing.bal` | Low | `ballerina:4` | Public methods of `DiscountCalculator` are not isolated (2 findings) |
| `pricing.bal` | Low | `ballerina:5` | `DiscountCalculator` is public but not isolated |
| `pricing.bal` | Low | `ballerina:6` | The `PaymentGateway` object type is public but not isolated |
| `pricing.bal` | Low | `ballerina:7` | A condition that is always true |
| `pricing.bal` | Low | `ballerina:8` | A condition that is always false |
| `pricing.bal` | Low | `ballerina:10` | A variable assigned to itself |
| `pricing.bal` | Low | `ballerina:11` | The private field `campaignCode` is never used |
| `pricing.bal` | Low | `ballerina:12` | The range `7 ... 1` is empty |

## GitHub code scanning

[`.github/workflows/scan.yml`](.github/workflows/scan.yml) runs on every push to `main` and `demo-base` and every pull request to them, and can be run by hand from the **Actions** tab. One job scans `order-service` with the category `order-service`:

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

| Pull request | Change | Ballerina Scan Tool | What the pull request shows | Merge |
| --- | --- | --- | --- | --- |
| [#29](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/29) `demo-1` | New findings, shown as annotations and not uploaded | No results | Annotations for 19 of the 33 findings, as GitHub shows at most 10 of each level per step. The suppressed `ledgerPoints` gets a comment of its own from the action, with the finding's severity, rule and message and the reason | Blocked, waiting for code scanning results |
| [#30](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/30) `demo-2` | No new findings | No new alerts | Nothing | Allowed |
| [#31](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/31) `demo-3` | New findings, one of them suppressed | 3 new alerts | Code scanning comments the 3 alerts. The suppressed `jwt:7` at `webhooks.bal:18` is one of them, and the action replies in its thread with the reason | Blocked |
| [#45](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/45) `demo-4` | New findings, all suppressed | 2 new alerts | Code scanning comments both, and the action replies to each with its reason | Blocked until both alerts are dismissed |
| [#46](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/46) `demo-5` | Suppresses `jwt:5`, already open on the base branch | No new alerts | Nothing: the alert is not new, and the finding's line is not one the pull request adds | Allowed. Its alert would be dismissed only by a merge to `main` |
| [#47](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/47) `demo-6` | Removes the suppression of `parseQuantity` | No new alerts | A warning at the finding that it is no longer suppressed, and that its alert stays dismissed on `main` until the change is merged there | Allowed |

### Demo pull requests to `main`

These pull requests show what each change does to the alerts in **Security > Code scanning** once merged. Each has an issue that gives the expected result, and they are merged one at a time, as each merge changes the alerts of `main`:

| Issue | Pull request | Change | What the pull request shows | Alert after the merge |
| --- | --- | --- | --- | --- |
| [#48](https://github.com/CharanaManawathilake/demo-scan-ballerina/issues/48) | [#53](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/53) | Suppresses `log:2`, open on `main` | Nothing | Closed, dismissed as *won't fix* with the reason |
| [#49](https://github.com/CharanaManawathilake/demo-scan-ballerina/issues/49) | Opened once #53 is merged | Removes that suppression again | A warning that the finding is no longer suppressed | Open again |
| [#50](https://github.com/CharanaManawathilake/demo-scan-ballerina/issues/50) | [#54](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/54) | Fixes `crypto:2` in `hashCustomerPassword` | Nothing | Closed as fixed |
| [#51](https://github.com/CharanaManawathilake/demo-scan-ballerina/issues/51) | [#55](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/55) | Removes `encryptCardNumber`, whose `crypto:1` finding is suppressed | Nothing | Closed as fixed, no longer *won't fix* |
| [#52](https://github.com/CharanaManawathilake/demo-scan-ballerina/issues/52) | [#56](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/56) | Adds `compressLog`, suppressed from the start | 1 new alert, with the reason as a reply. Blocked until it is dismissed | Stays closed, and its comment becomes the suppression's reason |

### Suppressed findings in pull requests

A finding accepted in the source with `@scan:Suppress` is left out of the counts and the gate, but it is still uploaded to code scanning, and its alert is only dismissed automatically on `main`. So in a pull request:

- A finding the pull request newly suppresses is a new alert. Code scanning comments on it, and the ruleset blocks the merge until someone allowed to dismiss alerts dismisses it ([#45](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/45), [#56](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/56)).
- The action replies to code scanning's comment with the reason given in the annotation, so the reviewer can decide. A finding code scanning does not comment, such as one in a run that does not upload, gets a comment of its own at its line ([#29](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/29)). Pushing again edits that comment rather than adding another.
- Suppressing a finding already on the base branch shows nothing ([#46](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/46)), and removing a suppression shows a warning ([#47](https://github.com/CharanaManawathilake/demo-scan-ballerina/pull/47)).
- Suppressed findings already on `main` are dismissed there, so they are not shown again.

The job needs `pull-requests: write` to comment. Runs for pull requests from forks have a read-only token, so they cannot comment, but their alerts are still shown.

Code scanning is free for public repositories. Private repositories need GitHub Advanced Security. The job needs `security-events: write` to upload and `actions: read` for the upload to read the workflow run.

## SonarQube

[`.github/workflows/sonarqube.yml`](.github/workflows/sonarqube.yml) runs on every push to `main`. One job scans `order-service` once and sends the findings to the SonarQube project `demo-scan-ballerina-order-service`.

It needs the repository variable `SONAR_HOST_URL` (an `https` URL) and the repository secret `SONAR_TOKEN`. The SonarQube server needs the Ballerina language plugin.

## Running the scan locally

```sh
cd order-service
bal scan --format=sarif
```

The report is written to `target/report/scan_results.sarif`. The service uses Ballerina 2201.13.5.
