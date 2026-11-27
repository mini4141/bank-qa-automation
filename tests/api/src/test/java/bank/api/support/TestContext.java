package bank.api.support;

import io.restassured.response.Response;
import java.util.HashMap;
import java.util.Map;

/** Per-scenario state shared between step classes (injected by PicoContainer). */
public class TestContext {
    public final BankApi api = new BankApi();
    public final Map<String, String> accounts = new HashMap<>();
    public Response lastResponse;
    public String idempotencyKey;
}
