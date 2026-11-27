@regression @web
Feature: Online banking
  Customers open accounts, move money and ask the assistant questions in the browser.

  @REQ-WEB-1 @smoke
  Scenario: Open an account via the UI
    Given I am on the bank home page
    When I open a "savings" account for "Web Tester"
    Then I see the account page for "Web Tester" with balance "$0.00"

  @REQ-WEB-2
  Scenario: Transfer money via the UI and see the fee
    Given I have an account "Sender" with balance 100
    And another customer account exists
    When I transfer "10.10" dollars to the other account
    Then the transfer confirmation shows a fee of "$0.15"
    And my balance is "$89.75"

  @REQ-WEB-3
  Scenario: The transaction list shows the transfer
    Given I have an account "Sender" with balance 50
    And another customer account exists
    When I transfer "10.00" dollars to the other account
    Then the transaction list shows 1 entry with "Sent $10.00"

  @REQ-WEB-4
  Scenario: The chat answer shows a citation link
    Given I am on the bank home page
    When I ask the assistant "How long is a cardless ATM code valid?"
    Then the answer links to the source "Cardless ATM withdrawal"

  @REQ-WEB-5 @visual
  Scenario: Visual snapshot of the account page
    Given I have an account "Visual Tester" with balance 250
    Then the account page looks as expected
