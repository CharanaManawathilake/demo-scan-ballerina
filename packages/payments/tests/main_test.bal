import ballerina/test;

// These findings are in tests/, so exclude-tests: true drops them and they are not counted.
@test:Config {}
isolated function testAmount() {
    // ballerina:1 (low): checkpanic instead of check.
    int amount = checkpanic int:fromString("100");

    // ballerina:10 (low): a variable assigned to itself.
    amount = amount;

    test:assertEquals(amount, 100);
}
