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

`bal scan` reports 34 findings for 31 rules, 8 high, 12 medium and 14 low:

| File | Severity | Rule | Issue |
| --- | --- | --- | --- |
| `auth.bal` | High | `ballerina/jwt:1` | Customer tokens are issued with the `none` algorithm |
| `auth.bal` | High | `ballerina/jwt:2` | Customer tokens are validated without a signature configuration |
| `auth.bal` | High | `ballerina/jwt:6` | TLS validation is turned off for the partner JWKS endpoint |
| `auth.bal` | Medium | `ballerina/jwt:3` | Customer tokens are validated without checking the issuer and audience |
| `auth.bal` | Medium | `ballerina/jwt:4` | Customer tokens expire after 30 days |
| `auth.bal` | Medium | `ballerina/jwt:5` | A clock skew of one hour |
| `auth.bal` | Medium | `ballerina:14` | The `Authorization` header is treated as a secret that is not configurable |
| `auth.bal` | Low | `ballerina/jwt:7` | A token is decoded without being verified |
| `auth.bal` | Low | `ballerina:3` | `issueToken` is public but not isolated |
| `payments.bal` | High | `ballerina:13` | The webhook signing secret is a literal value |
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

[`.github/workflows/scan.yml`](.github/workflows/scan.yml) runs on every push to `main` and every pull request to `main`, and can be run by hand from the **Actions** tab. One job scans `order-service` with the category `order-service`:

| Input | Value | Effect |
| --- | --- | --- |
| `platforms` | `github-code-scanning` | Uploads the findings to GitHub code scanning |
| `annotations` | `false` | No workflow annotations, so each finding appears once, as a code scanning alert |
| `artifacts` | `true` | Saves the SARIF file as an artifact |
| `job-summary` | `true` | Writes the high, medium and low counts to the job summary |
| `exclude-tests` | `true` | Drops findings in `tests/` |
| `fail-on-severity` | `high` on `main`, `none` on pull requests | Counts the high findings on `main` |
| `max-findings` | `5` | Fails the step when more than 5 high findings are counted |

The findings on `main` are under **Security > Code scanning**.

### Gating

The two kinds of gate count different findings:

| Where | Gate | Counts | Result |
| --- | --- | --- | --- |
| Push to `main` | `fail-on-severity` and `max-findings` in the action | Every finding in the package | `main` has 8 high findings and 5 are allowed, so the job fails |
| Pull request | Code scanning and the **Block new code scanning alerts** ruleset | Only the findings that are new compared with `main` | New alerts fail the **Ballerina Scan Tool** check and block the merge. No new alerts passes, even with the existing alerts on `main` |

The action's gate is off for pull requests because it would count the findings that are already on `main` and fail every pull request. The ruleset also needs code scanning results for every pull request, so a pull request that does not upload its findings cannot be merged either.

The demo pull requests show each case:

| Branch | Change | Result |
| --- | --- | --- |
| `demo-1` | New findings, with annotations and no upload | Blocked: code scanning waits for results that never come |
| `demo-2` | No new findings | Passes |
| `demo-3` | New findings, uploaded | Fails: the new alerts fail the **Ballerina Scan Tool** check |

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
