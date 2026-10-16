import ballerina/crypto;
import ballerina/io;

// ballerina:13 (high): a secret embedded as a literal value.
configurable string apiToken = "sk-demo-1234567890";

// ballerina/crypto:1 (medium): AES in ECB mode.
public isolated function sealCard(byte[] card, byte[16] key) returns byte[]|error {
    return crypto:encryptAesEcb(card, key);
}

// ballerina/crypto:1 (medium): RSA with PKCS1 padding.
public isolated function sealPin(byte[] pin, crypto:PublicKey key) returns byte[]|error {
    return crypto:encryptRsaEcb(pin, key, crypto:PKCS1);
}

// ballerina/crypto:2 (medium): a BCrypt work factor below 10.
public isolated function hashPassword(string password) returns string|error {
    return crypto:hashBcrypt(password, 4);
}

public function main() {
    // ballerina:1 (low): checkpanic instead of check.
    int amount = checkpanic int:fromString("100");

    // ballerina:10 (low): a variable assigned to itself.
    amount = amount;

    io:println(amount, apiToken.length());
}
