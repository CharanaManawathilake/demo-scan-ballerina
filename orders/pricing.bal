isolated function orderTotal(decimal[] itemPrices, decimal shipping) returns decimal {
    decimal total = 0;
    foreach decimal price in itemPrices {
        total += price;
    }
    return total > 100d ? total : total + shipping;
}

// Order quantities are sent as text by the storefront.
function parseQuantity(string raw) returns int {
    return checkpanic int:fromString(raw);
}
