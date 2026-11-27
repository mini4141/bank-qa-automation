@regression @accounts
Feature: Accounts
  As a customer I can open an account, deposit money and see my balance.

  @REQ-ACC-1 @smoke
  Scenario: Open a savings account
    When I open a "savings" account for "Alice Tester"
    Then the account is created with a zero balance

  @REQ-ACC-2
  Scenario: Deposit increases the balance
    Given an account "alice" with balance "100.00"
    When I deposit "25.50" into "alice"
    Then the balance of "alice" is "125.50"

  @REQ-ACC-3
  Scenario: Balance of an unknown account is not found
    When I look up an account that does not exist
    Then the response status is 404
