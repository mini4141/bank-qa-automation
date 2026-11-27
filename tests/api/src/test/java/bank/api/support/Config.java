package bank.api.support;

/** Service base URLs. Locally these are the compose ports; in the cloud they carry the ALB path prefix. */
public final class Config {
    private Config() {
    }

    public static String accountsUrl() {
        return env("ACCOUNTS_URL", "http://localhost:3001");
    }

    public static String transfersUrl() {
        return env("TRANSFERS_URL", "http://localhost:3002");
    }

    public static String chatUrl() {
        return env("CHAT_URL", "http://localhost:3003");
    }

    /** compose (default), k8s or none: how the resilience scenario takes the accounts service down. */
    public static String runtime() {
        return env("SUT_RUNTIME", "compose");
    }

    private static String env(String name, String fallback) {
        String value = System.getenv(name);
        return value == null || value.isBlank() ? fallback : value;
    }
}
