import ballerina/log;
import ballerina/scan;

@scan:Suppress {rules: ["ballerina/log:2"], reason: "The container mounts /tmp as a private volume, OPS-12"}
function init() returns error? {
    check log:setOutputFile("/tmp/order-service.log");
}
