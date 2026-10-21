import ballerina/crypto;

// ballerina:13 (high): a secret embedded as a literal value.
configurable string pricingApiKey = "pk-demo-1122334455";

// ballerina/crypto:2 (medium): a BCrypt work factor below 10.
public isolated function hashPriceCode(string code) returns string|error {
    return crypto:hashBcrypt(code, 5);
}

public function priceWithKey(int base) returns int {
    return base + pricingApiKey.length();
}
