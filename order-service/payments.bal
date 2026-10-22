import ballerina/crypto;
import ballerina/io;
import ballerina/log;

configurable string paymentGatewayKey = "pk_live_51HxOrderService000000000";
configurable byte[] cardEncryptionKey = ?;

final string webhookSigningSecret = "whsec_order_webhooks_2024";
final byte[16] receiptIv = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];

function encryptCardNumber(string cardNumber) returns byte[]|error {
    return crypto:encryptAesEcb(cardNumber.toBytes(), cardEncryptionKey);
}

function encryptReceipt(byte[] receipt) returns byte[]|error {
    return crypto:encryptAesGcm(receipt, cardEncryptionKey, receiptIv);
}

function hashCustomerPassword(string password) returns string|error {
    return crypto:hashBcrypt(password, 4);
}

function fingerprintCard(string cardNumber) returns string {
    return crypto:hashMd5(cardNumber.toBytes()).toBase16();
}

function verifyWebhook(string payload, string signature) returns boolean|error {
    byte[] expected = check crypto:hmacSha256(payload.toBytes(), webhookSigningSecret.toBytes());
    return expected.toBase16() == signature;
}

function refundPayment(string orderId, decimal amount) returns string|error {
    log:printInfo("Sending refund to the payment gateway", orderId = orderId, gatewayKey = paymentGatewayKey);
    io:println("Using gateway key ", paymentGatewayKey);
    return string `rf-${orderId}-${amount}`;
}
