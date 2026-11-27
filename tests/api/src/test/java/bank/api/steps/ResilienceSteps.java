package bank.api.steps;

import bank.api.support.SutRuntime;
import io.cucumber.java.After;
import io.cucumber.java.en.Given;

public class ResilienceSteps {

    @Given("the accounts service is stopped")
    public void accountsStopped() {
        SutRuntime.stopAccounts();
    }

    /** Always bring accounts back so later scenarios and suites are not affected. */
    @After("@resilience")
    public void restoreAccounts() {
        SutRuntime.startAccounts();
    }
}
