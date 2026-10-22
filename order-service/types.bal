public type Order record {|
    readonly string id;
    string customerId;
    decimal amount;
    string status;
|};

public type NewOrder record {|
    string customerId;
    decimal[] itemPrices;
    decimal shipping;
    string currency;
|};

public type RefundRequest record {|
    decimal amount;
    string reason;
|};
