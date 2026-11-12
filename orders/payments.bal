import ballerina/crypto;

configurable byte[] cardEncryptionKey = ?;

// Refunds are settled by the payment gateway, which returns this reference to the customer.
function refundReference(string orderId, decimal amount) returns string {
    return string `rf-${orderId}-${amount}`;
}

function hashCustomerPassword(string password) returns string|error {
    return crypto:hashBcrypt(password, 4);
}
