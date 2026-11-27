@regression @transfers
Feature: Transfers
  Money moves between accounts and the sender pays a 1.5 percent fee.

  @REQ-TRF-1 @smoke @fees
  Scenario: Happy path transfer charges the fee and credits the receiver
    Given an account "alice" with balance "100.00"
    And an account "bob" with balance "0.00"
    When I transfer "10.10" from "alice" to "bob"
    Then the transfer is created with a fee of "0.15"
    And the balance of "alice" is "89.75"
    And the balance of "bob" is "10.10"

  @REQ-TRF-2
  Scenario: Retrying with the same idempotency key does not move money twice
    Given an account "alice" with balance "50.00"
    And an account "bob" with balance "0.00"
    When I transfer "10.00" from "alice" to "bob" with idempotency key "retry-1"
    And I transfer "10.00" from "alice" to "bob" with idempotency key "retry-1"
    Then the second response status is 200
    And the balance of "bob" is "10.00"

  @REQ-TRF-3
  Scenario: Transfer above the available balance is rejected
    Given an account "alice" with balance "5.00"
    And an account "bob" with balance "0.00"
    When I transfer "20.00" from "alice" to "bob"
    Then the response status is 409
    And the error code is "INSUFFICIENT_FUNDS"

  @REQ-TRF-4
  Scenario: Transfers are listed for both accounts
    Given an account "alice" with balance "50.00"
    And an account "bob" with balance "0.00"
    When I transfer "10.00" from "alice" to "bob"
    Then the transfer list of "bob" has 1 entry
