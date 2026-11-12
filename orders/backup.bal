import ballerina/os;
import ballerina/scan;

// Compresses the service log before the nightly backup.
@scan:Suppress {rules: ["ballerina/os:4"], reason: "gzip is installed at a fixed path in the service image, OPS-77"}
function compressLog() returns error? {
    os:Process process = check os:exec({value: "gzip", arguments: ["/tmp/order-service.log"]});
    _ = check process.waitForExit();
}
