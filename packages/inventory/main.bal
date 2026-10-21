import ballerina/io;

public isolated function restock(int current, int amount) returns int {
    return current + amount;
}

public function main() {
    // ballerina:1 (low): checkpanic instead of check. Low is below the medium gate, so it passes.
    int stock = checkpanic int:fromString("10");
    io:println(restock(stock, 5));
}

// Clean change: adds no finding.
public isolated function reserve(int current, int amount) returns int {
    return current - amount;
}
