require 'alexa/request'

RSpec.describe Alexa::Request do
  describe '#slot_value' do
    it 'returns the value for a specific slot' do
      request_json = {
        "request": {
          "type": "IntentRequest",
          "intent": {
            "name": "IntentName",
            "slots": {
              "SlotName": {
                "name": "SlotName",
                "value": "10"
              }
            }
          }
        }
      }.to_json
      original_request_body = StringIO.new(request_json)
      original_request = double("Sinatra::Request", body: original_request_body)
      request = described_class.new(original_request)

      expect(request.slot_value("SlotName")).to eq "10"
    end
  end

  describe '#new_session?' do
    it 'is true if this is a new session' do
      request_json = {
        "session": {
          "sessionId": "id_string",
          "application": {
            "applicationId": "id_string"
          },
          "new": true
        }
      }.to_json
      original_request_body = StringIO.new(request_json)
      original_request = double("Sinatra::Request", body: original_request_body)
      request = described_class.new(original_request)

      expect(request.new_session?).to be true
    end

    it 'is false otherwise' do
      request_json = {
        "session": {
          "sessionId": "id_string",
          "application": {
            "applicationId": "id_string"
          },
          "new": false
        }
      }.to_json
      original_request_body = StringIO.new(request_json)
      original_request = double("Sinatra::Request", body: original_request_body)
      request = described_class.new(original_request)

      expect(request.new_session?).to be false
    end
  end
end