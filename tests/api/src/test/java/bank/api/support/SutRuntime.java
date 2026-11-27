package bank.api.support;

import java.io.IOException;
import java.nio.file.Path;
import java.time.Duration;
import java.util.List;

/** Starts and stops the accounts service on the runtime the suite runs against (compose or kind). */
public final class SutRuntime {
    private SutRuntime() {
    }

    public static void stopAccounts() {
        switch (Config.runtime()) {
            case "k8s" -> {
                run("kubectl", "scale", "deployment/accounts", "--replicas=0");
                // scaling is asynchronous: wait until the pod is really gone (a no-match error means it already is)
                runLenient("kubectl", "wait", "--for=delete", "pod", "-l", "app=accounts", "--timeout=60s");
            }
            default -> run("docker", "compose", "-p", "bank-qa", "-f", composeFile(), "stop", "accounts");
        }
    }

    public static void startAccounts() {
        switch (Config.runtime()) {
            case "k8s" -> {
                run("kubectl", "scale", "deployment/accounts", "--replicas=1");
                run("kubectl", "rollout", "status", "deployment/accounts", "--timeout=90s");
            }
            default -> run("docker", "compose", "-p", "bank-qa", "-f", composeFile(), "start", "accounts");
        }
        waitUntilHealthy();
    }

    private static void waitUntilHealthy() {
        long deadline = System.nanoTime() + Duration.ofSeconds(60).toNanos();
        while (System.nanoTime() < deadline) {
            try {
                if (new BankApi().health(Config.accountsUrl()).statusCode() == 200) {
                    return;
                }
            } catch (Exception ignored) {
                // still starting
            }
            sleep(1000);
        }
        throw new IllegalStateException("accounts-service did not become healthy again");
    }

    private static String composeFile() {
        return Path.of("..", "..", "docker-compose.yml").toAbsolutePath().normalize().toString();
    }

    private static void runLenient(String... command) {
        try {
            new ProcessBuilder(List.of(command)).inheritIO().start().waitFor();
        } catch (IOException e) {
            throw new IllegalStateException(e);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private static void run(String... command) {
        try {
            Process process = new ProcessBuilder(List.of(command)).inheritIO().start();
            if (process.waitFor() != 0) {
                throw new IllegalStateException("command failed: " + String.join(" ", command));
            }
        } catch (IOException e) {
            throw new IllegalStateException(e);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException(e);
        }
    }

    private static void sleep(long millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
