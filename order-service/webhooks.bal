import ballerina/jwt;
import ballerina/log;
import ballerina/scan;

configurable string carrierWebhookToken = ?;

final string carrierSigningSecret = "carrier_whsec_9d8e7f6a";

// Shipping carriers call back with a token that names the carrier.
function carrierFromWebhook(string token) returns string|error {
    [jwt:Header, jwt:Payload] [_, payload] = check jwt:decode(token);
    log:printInfo("Carrier webhook received", token = carrierWebhookToken);
    return payload.iss ?: "";
}

@scan:Suppress {rules: ["ballerina/jwt:7"], reason: "The carrier sandbox sends unsigned tokens and accepts no real shipments"}
function carrierFromSandboxWebhook(string token) returns string|error {
    [jwt:Header, jwt:Payload] [_, payload] = check jwt:decode(token);
    return payload.iss ?: "";
}

function carrierSignature(string payload) returns string {
    return payload + carrierSigningSecret;
}
