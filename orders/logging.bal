import ballerina/log;

function init() returns error? {
    check log:setOutputFile("/tmp/order-service.log");
}
