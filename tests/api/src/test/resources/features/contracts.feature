@regression @contract
Feature: Service contracts
  Each service exposes a health endpoint and the response shapes other services rely on.

  @REQ-CON-1 @smoke
  Scenario Outline: <service> reports healthy
    When I check the health of the <service> service
    Then the response status is 200
    And the health status is "ok"

    Examples:
      | service   |
      | accounts  |
      | transfers |
      | chat      |

  @REQ-CON-2
  Scenario: The account payload has the fields the transfers service depends on
    When I open a "checking" account for "Contract Tester"
    Then the account payload contains id, name, type and balanceMinor
