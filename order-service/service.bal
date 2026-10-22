import ballerina/file;
import ballerina/http;
import ballerina/io;
import ballerina/os;
import ballerina/uuid;

final http:Client shippingClient = check new ("https://shipping.internal.example.com");

@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: true
    }
}
service /orders on new http:Listener(9090) {

    resource function get [string orderId](http:Request req) returns Order|http:NotFound|error {
        _ = check authenticate(req);
        return findOrder(orderId) ?: http:NOT_FOUND;
    }

    resource function post .(http:Request req, NewOrder newOrder) returns Order|error {
        _ = check authenticate(req);
        Order created = {
            id: uuid:createType4AsString(),
            customerId: newOrder.customerId,
            amount: orderTotal(newOrder.itemPrices, newOrder.shipping, newOrder.currency),
            status: "PENDING"
        };
        saveOrder(created);
        return created;
    }

    resource function post [string orderId]/refund(http:Request req, RefundRequest refund) returns json|error {
        _ = check authenticate(req);
        string reference = check refundPayment(orderId, refund.amount);
        return {orderId, reference, status: "REFUNDED"};
    }

    resource function get [string orderId]/tracking(string carrierPath) returns json|error {
        return shippingClient->get(carrierPath);
    }

    resource function get checkout/complete(string returnUrl) returns http:TemporaryRedirect {
        return {headers: {"Location": returnUrl}};
    }

    resource function get invoices/[string fileName]() returns byte[]|error {
        string path = check file:joinPath(INVOICE_DIR, fileName);
        return io:fileReadBytes(path);
    }

    resource function post reports/export(string format, string locale) returns string|error {
        os:Process process = check os:exec({value: "/usr/local/bin/generate-report", arguments: ["--format", format]},
            LANG = locale);
        _ = check process.waitForExit();
        return exportReport(format);
    }

    resource function 'default [string... path]() returns http:NotFound {
        return http:NOT_FOUND;
    }
}
