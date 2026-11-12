import ballerina/http;
import ballerina/jwt;
import ballerina/scan;

configurable string jwtIssuer = "order-service";
configurable string jwtCertFile = "/etc/order-service/jwt.crt";

@scan:Suppress {rules: ["ballerina/jwt:5"], reason: "Partner clocks drift up to an hour until PART-90 moves them to NTP"}
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
