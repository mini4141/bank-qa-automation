package bank.api.steps;

import static org.assertj.core.api.Assertions.assertThat;

import bank.api.support.Config;
import bank.api.support.TestContext;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

public class HealthSteps {
    private final TestContext ctx;

    public HealthSteps(TestContext ctx) {
        this.ctx = ctx;
    }

    @When("I check the health of the {word} service")
    public void checkHealth(String service) {
        String url = switch (service) {
            case "accounts" -> Config.accountsUrl();
            case "transfers" -> Config.transfersUrl();
            default -> Config.chatUrl();
        };
        ctx.lastResponse = ctx.api.health(url);
    }

    @Then("the health status is {string}")
    public void healthStatus(String status) {
        assertThat(ctx.lastResponse.jsonPath().getString("status")).isEqualTo(status);
    }
}
