import ballerina/jwt;
import ballerina/log;

configurable string carrierWebhookToken = ?;

final string carrierSigningSecret = "carrier_whsec_9d8e7f6a";

// Shipping carriers call back with a token that names the carrier.
function carrierFromWebhook(string token) returns string|error {
    [jwt:Header, jwt:Payload] [_, payload] = check jwt:decode(token);
    log:printInfo("Carrier webhook received", token = carrierWebhookToken);
    return payload.iss ?: "";
}

function carrierSignature(string payload) returns string {
    return payload + carrierSigningSecret;
}
