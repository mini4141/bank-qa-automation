package bank.api.steps;

import static org.assertj.core.api.Assertions.assertThat;

import bank.api.support.AccountBuilder;
import bank.api.support.Money;
import bank.api.support.TestContext;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import java.util.List;
import java.util.Set;

public class AccountSteps {
    private final TestContext ctx;

    public AccountSteps(TestContext ctx) {
        this.ctx = ctx;
    }

    @Given("an account {string} with balance {string}")
    public void anAccountWithBalance(String alias, String dollars) {
        ctx.accounts.put(alias, AccountBuilder.anAccount().named(alias).withBalance(dollars).create(ctx.api));
    }

    @When("I open a {string} account for {string}")
    public void iOpenAnAccount(String type, String name) {
        ctx.lastResponse = ctx.api.openAccount(name, type);
    }

    @When("I deposit {string} into {string}")
    public void iDeposit(String dollars, String alias) {
        ctx.lastResponse = ctx.api.deposit(ctx.accounts.get(alias), Money.minor(dollars));
    }

    @When("I look up an account that does not exist")
    public void iLookUpMissingAccount() {
        ctx.lastResponse = ctx.api.getAccount("does-not-exist");
    }

    @Then("the account is created with a zero balance")
    public void accountCreatedWithZeroBalance() {
        ctx.lastResponse.then().statusCode(201);
        assertThat(ctx.lastResponse.jsonPath().getLong("balanceMinor")).isZero();
        assertThat(ctx.lastResponse.jsonPath().getString("id")).isNotBlank();
    }

    @Then("the account payload contains id, name, type and balanceMinor")
    public void accountPayloadShape() {
        assertThat(ctx.lastResponse.jsonPath().getMap("$").keySet())
                .containsAll(Set.of("id", "name", "type", "balanceMinor"));
    }

    @Then("the balance of {string} is {string}")
    public void balanceIs(String alias, String dollars) {
        long actual = ctx.api.getAccount(ctx.accounts.get(alias)).jsonPath().getLong("balanceMinor");
        assertThat(actual).as("balance of %s in minor units", alias).isEqualTo(Money.minor(dollars));
    }

    @Then("the response status is {int}")
    public void responseStatus(int status) {
        assertThat(ctx.lastResponse.statusCode()).as(ctx.lastResponse.asString()).isEqualTo(status);
    }

    @Then("the error code is {string}")
    public void errorCode(String code) {
        assertThat(ctx.lastResponse.jsonPath().getString("error")).isEqualTo(code);
    }

    @Then("the transfer list of {string} has {int} entry")
    public void transferListSize(String alias, int size) {
        List<?> list = ctx.api.listTransfers(ctx.accounts.get(alias)).jsonPath().getList("$");
        assertThat(list).hasSize(size);
    }
}
