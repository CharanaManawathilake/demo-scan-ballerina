// Orders are kept in memory until the order database is provisioned.
isolated table<Order> key(id) orders = table [];

isolated function findOrder(string orderId) returns Order? {
    lock {
        return orders[orderId].clone();
    }
}

isolated function saveOrder(Order 'order) {
    lock {
        orders.put('order.clone());
    }
}
