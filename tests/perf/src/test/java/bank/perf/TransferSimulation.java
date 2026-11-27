package bank.perf;

import static io.gatling.javaapi.core.CoreDsl.details;
import static io.gatling.javaapi.core.CoreDsl.global;
import static io.gatling.javaapi.core.CoreDsl.jsonPath;
import static io.gatling.javaapi.core.CoreDsl.rampUsers;
import static io.gatling.javaapi.core.CoreDsl.scenario;
import static io.gatling.javaapi.core.CoreDsl.StringBody;
import static io.gatling.javaapi.http.HttpDsl.http;
import static io.gatling.javaapi.http.HttpDsl.status;

import io.gatling.javaapi.core.ScenarioBuilder;
import io.gatling.javaapi.core.Simulation;
import io.gatling.javaapi.http.HttpProtocolBuilder;
import java.time.Duration;

/**
 * Each virtual user opens two accounts, funds one and transfers between them.
 * Profile: ramp to {users} users over {rampSeconds}. Assertions: transfer p95 under 500 ms, under 1 percent failures.
 * Override with the USERS and RAMP_SECONDS environment variables for the lighter cloud / CI smoke profile.
 */
public class TransferSimulation extends Simulation {

    private static String env(String name, String fallback) {
        String value = System.getenv(name);
        return value == null || value.isBlank() ? fallback : value;
    }

    private static final String ACCOUNTS = env("ACCOUNTS_URL", "http://localhost:3001");
    private static final String TRANSFERS = env("TRANSFERS_URL", "http://localhost:3002");
    private static final int USERS = Integer.parseInt(env("USERS", "50"));
    private static final int RAMP_SECONDS = Integer.parseInt(env("RAMP_SECONDS", "60"));

    private final HttpProtocolBuilder protocol = http
            .acceptHeader("application/json")
            .contentTypeHeader("application/json");

    private final ScenarioBuilder transfer = scenario("Open, fund and transfer")
            .exec(http("open sender").post(ACCOUNTS + "/accounts")
                    .body(StringBody("{\"name\":\"Perf Sender\",\"type\":\"checking\"}"))
                    .check(status().is(201), jsonPath("$.id").saveAs("fromId")))
            .exec(http("open receiver").post(ACCOUNTS + "/accounts")
                    .body(StringBody("{\"name\":\"Perf Receiver\",\"type\":\"savings\"}"))
                    .check(status().is(201), jsonPath("$.id").saveAs("toId")))
            .exec(http("fund sender").post(session -> ACCOUNTS + "/accounts/" + session.getString("fromId") + "/deposits")
                    .body(StringBody("{\"amountMinor\":100000}"))
                    .check(status().is(200)))
            .exec(http("transfer").post(TRANSFERS + "/transfers")
                    .body(StringBody("{\"fromId\":\"#{fromId}\",\"toId\":\"#{toId}\",\"amountMinor\":1000}"))
                    .check(status().is(201)))
            .exec(http("get account").get(session -> ACCOUNTS + "/accounts/" + session.getString("fromId"))
                    .check(status().is(200)));

    {
        setUp(transfer.injectOpen(rampUsers(USERS).during(Duration.ofSeconds(RAMP_SECONDS))))
                .protocols(protocol)
                .assertions(
                        details("transfer").responseTime().percentile(95).lt(500),
                        global().failedRequests().percent().lt(1.0));
    }
}
