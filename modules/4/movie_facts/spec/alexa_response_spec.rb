require 'alexa/response'

RSpec.describe Alexa::Response do
  subject(:response) { described_class.new }

  describe '#to_json' do
    it 'returns a JSON response with a custom string if provided' do
      expected_response = {
        version: "1.0",
        response: {
          outputSpeech: {
              type: "PlainText",
              text: "Custom String"
            }
        }
      }.to_json

      custom_response = described_class.new("Custom String").to_json
      expect(custom_response).to eq expected_response
    end

    it 'returns a JSON response with session data if provided' do
      expected_response = { 
        version: "1.0",
        sessionAttributes: {
          sessionKey: "Session Value"
        },
        response: {
          outputSpeech: {
              type: "PlainText",
              text: "Custom String"
            }
        }
      }.to_json

      session_response = described_class.new("Custom String", { sessionKey: "SessionValue" }).to_json
      expect(session_response).to eq expected_response
    end

    it 'returns a minimal JSON response otherwise' do
      minimal_response = { 
        version: "1.0",
        response: {
          outputSpeech: {
              type: "PlainText",
              text: "Hello World"
            }
        }
      }.to_json
      
      expect(response.to_json).to eq minimal_response
    end
  end
end