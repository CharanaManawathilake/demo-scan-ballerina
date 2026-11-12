import ballerina/scan;

isolated function orderTotal(decimal[] itemPrices, decimal shipping) returns decimal {
    decimal total = 0;
    foreach decimal price in itemPrices {
        total += price;
    }
    return total > 100d ? total : total + shipping;
}

// Order quantities are sent as text by the storefront.
@scan:Suppress {rules: ["ballerina:1"], reason: "Quantities are validated by the API gateway, API-204"}
function parseQuantity(string raw) returns int {
    return checkpanic int:fromString(raw);
}
