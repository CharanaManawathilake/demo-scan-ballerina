import ballerina/file;
import ballerina/log;
import ballerina/os;
import ballerina/scan;

const string INVOICE_DIR = "/var/lib/orders/invoices";
const string REPORT_DIR = "/tmp/order-reports";

@scan:Suppress {rules: ["ballerina/log:2"], reason: "The container mounts /tmp as a private volume, OPS-12"}
function init() returns error? {
    check log:setOutputFile("/tmp/order-service.log");
}

function exportReport(string format) returns string|error {
    check file:createDir(REPORT_DIR, file:RECURSIVE);
    os:Process process = check os:exec({value: "sh", arguments: ["-c", "generate-report --format " + format]});
    _ = check process.waitForExit();
    return REPORT_DIR;
}

// Archives the reports for the nightly backup.
function archiveReports() returns error? {
    os:Process process = check os:exec({value: "tar", arguments: ["-czf", "reports.tgz", REPORT_DIR]});
    _ = check process.waitForExit();
}
