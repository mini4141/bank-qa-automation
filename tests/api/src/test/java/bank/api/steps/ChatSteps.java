package bank.api.steps;

import static org.assertj.core.api.Assertions.assertThat;

import bank.api.support.TestContext;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import java.util.List;

public class ChatSteps {
    private final TestContext ctx;

    public ChatSteps(TestContext ctx) {
        this.ctx = ctx;
    }

    @When("I ask the assistant {string}")
    public void iAsk(String question) {
        ctx.lastResponse = ctx.api.ask(question);
        ctx.lastResponse.then().statusCode(200);
    }

    @Then("the answer mentions {string}")
    public void answerMentions(String text) {
        assertThat(ctx.lastResponse.jsonPath().getString("answer")).contains(text);
    }

    @Then("the answer cites the document {string}")
    public void answerCites(String docId) {
        List<String> ids = ctx.lastResponse.jsonPath().getList("citations.docId");
        assertThat(ids).contains(docId);
    }

    @Then("the answer says it does not know")
    public void answerDeclines() {
        assertThat(ctx.lastResponse.jsonPath().getString("answer")).contains("don't know");
    }

    @Then("the answer has no citations")
    public void noCitations() {
        assertThat(ctx.lastResponse.jsonPath().getList("citations")).isEmpty();
    }
}
