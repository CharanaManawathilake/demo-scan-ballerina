import ballerina/http;
import ballerina/uuid;

service /orders on new http:Listener(9090) {

    resource function get [string orderId](http:Request req) returns Order|http:NotFound|error {
        _ = check authenticate(req);
        return findOrder(orderId) ?: http:NOT_FOUND;
    }

    resource function delete [string orderId](http:Request req) returns Order|http:NotFound|error {
        _ = check authenticate(req);
        return removeOrder(orderId) ?: http:NOT_FOUND;
    }

    resource function post .(http:Request req, NewOrder newOrder) returns Order|error {
        _ = check authenticate(req);
        Order created = {
            id: uuid:createType4AsString(),
            customerId: newOrder.customerId,
            amount: orderTotal(newOrder.itemPrices, newOrder.shipping),
            status: "PENDING"
        };
        saveOrder(created);
        return created;
    }

    resource function post [string orderId]/refund(http:Request req, RefundRequest refund) returns json|error {
        _ = check authenticate(req);
        return {orderId, reference: refundReference(orderId, refund.amount), status: "REFUNDED"};
    }
}
