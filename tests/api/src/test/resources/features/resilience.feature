@regression @resilience @needs-runtime-control
Feature: Microservice resilience
  Transfers depends on accounts, so it must fail clearly when accounts is down.

  @REQ-RES-1
  Scenario: Transfers returns 503 with a clear error when accounts is down
    Given an account "alice" with balance "50.00"
    And an account "bob" with balance "0.00"
    And the accounts service is stopped
    When I transfer "5.00" from "alice" to "bob"
    Then the response status is 503
    And the error code is "ACCOUNTS_UNAVAILABLE"
