import ballerina/crypto;

final string loyaltyPartnerSecret = "lp_secret_7f3a9c21";

// Customers earn one point for every whole unit spent on an order.
function loyaltyPoints(Order 'order) returns int {
    int points = <int>'order.amount;
    points = points;
    return points;
}

function redeemPoints(string rawPoints) returns int {
    return checkpanic int:fromString(rawPoints);
}

function loyaltyCardHash(string cardNumber) returns string|error {
    return crypto:hashBcrypt(cardNumber + loyaltyPartnerSecret, 6);
}
