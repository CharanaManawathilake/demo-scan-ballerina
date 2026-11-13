// Discount codes and their amounts are sent as text by the storefront.

function percentOff(string raw) returns int {
    return checkpanic int:fromString(raw);
}

function fixedOff(string raw) returns decimal {
    return checkpanic decimal:fromString(raw);
}

function minimumSpend(string raw) returns decimal {
    return checkpanic decimal:fromString(raw);
}
