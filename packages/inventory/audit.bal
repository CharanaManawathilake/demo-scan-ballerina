import ballerina/crypto;

// ballerina/crypto:1 (medium): AES in ECB mode.
public isolated function sealAuditRecord(byte[] 'record, byte[16] key) returns byte[]|error {
    return crypto:encryptAesEcb('record, key);
}

public function auditCount(string count) returns int {
    // ballerina:1 (low): checkpanic instead of check.
    int total = checkpanic int:fromString(count);
    // ballerina:10 (low): a variable assigned to itself.
    total = total;
    return total;
}
