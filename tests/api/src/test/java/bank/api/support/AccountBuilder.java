package bank.api.support;

/** Test data builder: an account that exists in the SUT with a given opening balance. */
public class AccountBuilder {
    private String name = "Test Customer";
    private String type = "checking";
    private long balanceMinor = 0;

    public static AccountBuilder anAccount() {
        return new AccountBuilder();
    }

    public AccountBuilder named(String name) {
        this.name = name;
        return this;
    }

    public AccountBuilder ofType(String type) {
        this.type = type;
        return this;
    }

    public AccountBuilder withBalance(String dollars) {
        this.balanceMinor = Money.minor(dollars);
        return this;
    }

    /** Creates the account through the API and returns its id. */
    public String create(BankApi api) {
        String id = api.openAccount(name, type).then().statusCode(201).extract().path("id");
        if (balanceMinor > 0) {
            api.deposit(id, balanceMinor).then().statusCode(200);
        }
        return id;
    }
}
