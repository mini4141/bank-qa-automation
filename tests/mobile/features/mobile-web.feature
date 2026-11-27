@regression @mobile
Feature: Mobile web banking
  The responsive web app works in Chrome on an Android emulator.

  @REQ-MOB-1 @smoke
  Scenario: Open an account on a phone
    Given I open the bank site on the phone
    When I open a "savings" account for "Mobile Tester" on the phone
    Then the phone shows the account page for "Mobile Tester"

  @REQ-MOB-2
  Scenario: Transfer money on a phone
    Given a funded account "Mobile Sender" with 100 dollars exists
    And another customer account exists for the phone
    When I open that account on the phone
    And I transfer "10.10" dollars to the other account on the phone
    Then the phone shows the transfer confirmation with a fee of "$0.15"

  @REQ-MOB-3
  Scenario: Ask the assistant on a phone
    Given I open the bank site on the phone
    When I ask the assistant "How long is a cardless ATM code valid?" on the phone
    Then the phone shows an answer with a source link
