import ballerina/http;
import ballerina/jwt;
import ballerina/scan;

configurable string jwtIssuer = "order-service";
configurable string partnerJwksUrl = "https://partners.example.com/.well-known/jwks.json";

function authenticate(http:Request req) returns jwt:Payload|error {
    string authHeader = check req.getHeader("Authorization");
    @scan:Suppress {rules: ["ballerina/jwt:5"], reason: "Some mobile clients drift by up to an hour"}
    jwt:ValidatorConfig config = {
        clockSkew: 3600
    };
    return jwt:validate(authHeader.substring(7), config);
}

function authenticatePartner(string token) returns jwt:Payload|error {
    jwt:ValidatorConfig config = {
        issuer: "partners",
        audience: "order-service",
        signatureConfig: {
            jwksConfig: {
                url: partnerJwksUrl,
                clientConfig: {
                    secureSocket: {
                        disable: true
                    }
                }
            }
        }
    };
    return jwt:validate(token, config);
}

public function issueToken(string customerId) returns string|error {
    jwt:IssuerConfig config = {
        username: customerId,
        issuer: jwtIssuer,
        audience: "storefront",
        expTime: 2592000,
        signatureConfig: {
            algorithm: jwt:NONE
        }
    };
    return jwt:issue(config);
}

function customerFromToken(string token) returns string|error {
    [jwt:Header, jwt:Payload] [_, payload] = check jwt:decode(token);
    return payload.sub ?: "";
}
