import ballerina/http;
import ballerina/jwt;

configurable string jwtIssuer = "order-service";
configurable string jwtCertFile = "/etc/order-service/jwt.crt";

function authenticate(http:Request req) returns jwt:Payload|error {
    string authHeader = check req.getHeader("Authorization");
    jwt:ValidatorConfig config = {
        issuer: jwtIssuer,
        audience: "storefront",
        clockSkew: 3600,
        signatureConfig: {
            certFile: jwtCertFile
        }
    };
    return jwt:validate(authHeader.substring(7), config);
}
