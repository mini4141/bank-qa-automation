package bank.api.support;

import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import io.restassured.specification.RequestSpecification;
import java.util.Map;

/** Thin Rest-Assured client over the three services. */
public class BankApi {

    private static RequestSpecification json(String baseUri) {
        return RestAssured.given().baseUri(baseUri).contentType(ContentType.JSON).accept(ContentType.JSON);
    }

    public Response openAccount(String name, String type) {
        return json(Config.accountsUrl()).body(Map.of("name", name, "type", type)).post("/accounts");
    }

    public Response getAccount(String id) {
        return json(Config.accountsUrl()).get("/accounts/{id}", id);
    }

    public Response deposit(String id, long amountMinor) {
        return json(Config.accountsUrl()).body(Map.of("amountMinor", amountMinor)).post("/accounts/{id}/deposits", id);
    }

    public Response transfer(String fromId, String toId, long amountMinor, String idempotencyKey) {
        RequestSpecification spec = json(Config.transfersUrl())
                .body(Map.of("fromId", fromId, "toId", toId, "amountMinor", amountMinor));
        if (idempotencyKey != null) {
            spec = spec.header("Idempotency-Key", idempotencyKey);
        }
        return spec.post("/transfers");
    }

    public Response listTransfers(String accountId) {
        return json(Config.transfersUrl()).queryParam("accountId", accountId).get("/transfers");
    }

    public Response ask(String question) {
        return json(Config.chatUrl()).body(Map.of("question", question)).post("/chat");
    }

    public Response health(String baseUrl) {
        return RestAssured.given().baseUri(baseUrl).get("/healthz");
    }
}
