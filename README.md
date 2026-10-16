# demo-scan-ballerina

A demo of the [scan-ballerina](https://github.com/CharanaManawathilake/scan-ballerina) action. It runs `bal scan` on two Ballerina packages in one workflow and gives each scan its own category. One scan fails the build at the severity gate and the other passes.

## The workflow

[`.github/workflows/scan.yml`](.github/workflows/scan.yml) runs on every push to `main` and on every pull request to `main`. You can also run it by hand from the **Actions** tab with **Run workflow**.

It has one job with two scan steps:

| Step | Category | Package | Expected |
| --- | --- | --- | --- |
| Scan payments | `payments` | `packages/payments` | Fails at the gate: 4 findings at or above medium, and only 2 are allowed |
| Scan inventory | `inventory` | `packages/inventory` | Passes: its only finding is low, which is below the gate |

Both steps use the same settings:

| Input | Value | Effect |
| --- | --- | --- |
| `fail-on-severity` | `medium` | Counts the findings at medium or high |
| `max-findings` | `2` | Fails the step when more than 2 findings are counted |
| `exclude-tests` | `true` | Drops the findings in `tests/` |
| `platforms` | `github-code-scanning` | Uploads the findings to GitHub code scanning |
| `artifacts` | `true` | Saves the SARIF file as an artifact named after the category |
| `annotations` | `true` | Shows each counted finding on its file and line |
| `job-summary` | `true` | Writes the result and the high, medium and low counts to the job summary |

The inventory step has `if: ${{ !cancelled() }}`, so it still runs after the payments step fails. The job and the workflow run fail because the payments step failed.

## The findings

### payments

[`packages/payments/main.bal`](packages/payments/main.bal) has six findings:

| Severity | Rule | Issue |
| --- | --- | --- |
| High | `ballerina:13` | A secret embedded as a literal value in `apiToken` |
| Medium | `ballerina/crypto:1` | AES in ECB mode in `sealCard` |
| Medium | `ballerina/crypto:1` | RSA with PKCS1 padding in `sealPin` |
| Medium | `ballerina/crypto:2` | A BCrypt work factor of 4 in `hashPassword` |
| Low | `ballerina:1` | `checkpanic` instead of `check` in `main` |
| Low | `ballerina:10` | A variable assigned to itself in `main` |

[`packages/payments/tests/main_test.bal`](packages/payments/tests/main_test.bal) has two more low findings, `ballerina:1` and `ballerina:10`. `exclude-tests: true` drops them, so the scan reports 1 high, 3 medium and 2 low.

The gate counts the 4 findings at or above medium. That is more than `max-findings: 2`, so the step fails.

### inventory

[`packages/inventory/main.bal`](packages/inventory/main.bal) has one finding, a low `ballerina:1` for `checkpanic`. Low is below `medium`, so no finding is counted and the step passes.

## Where to see the results

After a push to `main`, open the workflow run in the **Actions** tab:

- **Job summary**: one for each category, from `job-summary: true`, with the result and the high, medium and low counts.
- **Artifacts**: `payments` and `inventory`, each holding that scan's SARIF file. The payments file is saved even though its step failed.
- **Annotations**: the 4 counted findings of payments, on their files and lines.

The findings are also under **Security > Code scanning**. Each category is uploaded as its own analysis, so a later run of one category replaces only that category's findings.

## Setting up

- Code scanning must be available on the repository. It is free for public repositories, and private repositories need GitHub Advanced Security.
- The job has `security-events: write` to upload to code scanning and `actions: read` for the upload to read the workflow run.
- The packages use Ballerina 2201.13.5, which the workflow installs.

## Running the scan locally

```sh
cd packages/payments
bal scan --format=sarif
```

The report is written to `target/report/scan_results.sarif`. `bal scan` does not drop the findings in `tests/`, so it lists 8 findings. The action drops the 2 in `tests/`.

## SonarQube

[`.github/workflows/sonarqube.yml`](.github/workflows/sonarqube.yml) scans both packages and sends the findings to SonarQube on every push to `main`. Each package goes to its own project: `demo-scan-ballerina-payments` and `demo-scan-ballerina-inventory`. It has no gate, so it passes whatever the findings are.

It needs two repository secrets, `SONAR_HOST_URL` (an `https` URL) and `SONAR_TOKEN`, and the SonarQube server needs the Ballerina language plugin.
