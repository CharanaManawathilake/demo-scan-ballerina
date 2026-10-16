import ballerina/crypto;

// ballerina:13 (high): a secret embedded as a literal value.
configurable string refundToken = "rf-demo-0987654321";

// ballerina/crypto:1 (medium): AES in ECB mode.
public isolated function sealRefund(byte[] refund, byte[16] key) returns byte[]|error {
    return crypto:encryptAesEcb(refund, key);
}

// ballerina/crypto:2 (medium): a BCrypt work factor below 10.
public isolated function hashRefundCode(string code) returns string|error {
    return crypto:hashBcrypt(code, 6);
}

public function refund(string amount) returns int {
    // ballerina:1 (low): checkpanic instead of check.
    int value = checkpanic int:fromString(amount);
    return value + refundToken.length();
}
