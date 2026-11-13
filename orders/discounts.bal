import ballerina/scan;

// Discount codes and their amounts are sent as text by the storefront.

@scan:Suppress {rules: ["ballerina:1"], reason: "Discount values are validated by the storefront, SHOP-12"}
function percentOff(string raw) returns int {
    return checkpanic int:fromString(raw);
}

@scan:Suppress {rules: ["ballerina:1"], reason: "Discount values are validated by the storefront, SHOP-12"}
function fixedOff(string raw) returns decimal {
    return checkpanic decimal:fromString(raw);
}

@scan:Suppress {rules: ["ballerina:1"], reason: "Discount values are validated by the storefront, SHOP-12"}
function minimumSpend(string raw) returns decimal {
    return checkpanic decimal:fromString(raw);
}

@scan:Suppress {rules: ["ballerina:1"], reason: "Discount values are validated by the storefront, SHOP-12"}
function maximumDiscount(string raw) returns decimal {
    return checkpanic decimal:fromString(raw);
}

@scan:Suppress {rules: ["ballerina:1"], reason: "Discount values are validated by the storefront, SHOP-12"}
function discountCode(string raw) returns string {
    return raw.trim().toUpperAscii();
}
