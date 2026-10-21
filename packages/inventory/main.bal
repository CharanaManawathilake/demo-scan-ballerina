// Demo: header comment added to shift line numbers.
// Checks whether a dismissed alert is raised again on a later push.

import ballerina/crypto;
import ballerina/io;

public isolated function restock(int current, int amount) returns int {
    return current + amount;
}

// ballerina/crypto:2 (medium): a BCrypt work factor below 10.
public isolated function hashSku(string sku) returns string|error {
    return crypto:hashBcrypt(sku, 4);
}

public function main() {
    // ballerina:1 (low): checkpanic instead of check. Low is below the medium gate, so it passes.
    int stock = checkpanic int:fromString("10");

    // ballerina:10 (low): a variable assigned to itself.
    stock = stock;

    io:println(restock(stock, 5));
}
