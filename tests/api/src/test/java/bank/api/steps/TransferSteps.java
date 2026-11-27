package bank.api.steps;

import static org.assertj.core.api.Assertions.assertThat;

import bank.api.support.Money;
import bank.api.support.TestContext;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import io.restassured.response.Response;

public class TransferSteps {
    private final TestContext ctx;
    private Response firstResponse;

    public TransferSteps(TestContext ctx) {
        this.ctx = ctx;
    }

    @When("I transfer {string} from {string} to {string}")
    public void iTransfer(String dollars, String from, String to) {
        ctx.lastResponse = ctx.api.transfer(ctx.accounts.get(from), ctx.accounts.get(to), Money.minor(dollars), null);
    }

    @When("I transfer {string} from {string} to {string} with idempotency key {string}")
    public void iTransferWithKey(String dollars, String from, String to, String key) {
        // Keys are unique per scenario run (the database outlives it) but identical across the retry.
        String uniqueKey = key + "-" + ctx.accounts.get(from);
        Response response = ctx.api.transfer(ctx.accounts.get(from), ctx.accounts.get(to), Money.minor(dollars), uniqueKey);
        if (firstResponse == null) {
            firstResponse = response;
        }
        ctx.lastResponse = response;
    }

    @Then("the transfer is created with a fee of {string}")
    public void feeIs(String dollars) {
        ctx.lastResponse.then().statusCode(201);
        assertThat(ctx.lastResponse.jsonPath().getLong("feeMinor")).as("fee in minor units").isEqualTo(Money.minor(dollars));
    }

    @Then("the second response status is {int}")
    public void secondResponseStatus(int status) {
        assertThat(firstResponse.statusCode()).isEqualTo(201);
        assertThat(ctx.lastResponse.statusCode()).isEqualTo(status);
        assertThat(ctx.lastResponse.jsonPath().getString("id")).isEqualTo(firstResponse.jsonPath().getString("id"));
    }
}
