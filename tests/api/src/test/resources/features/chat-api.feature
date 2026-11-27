@regression @chat
Feature: Inquiry chat API
  The assistant answers FAQ questions from the bundled policy documents and cites its sources.

  @REQ-CHAT-1 @smoke
  Scenario: A cardless ATM question returns a grounded answer with a citation
    When I ask the assistant "How long is a cardless ATM code valid?"
    Then the answer mentions "30 minutes"
    And the answer cites the document "cardless-atm"

  @REQ-CHAT-2
  Scenario: An out-of-scope question is declined without citations
    When I ask the assistant "What is the weather in Paris today?"
    Then the answer says it does not know
    And the answer has no citations
