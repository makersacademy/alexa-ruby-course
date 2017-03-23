require './alexa/response'

RSpec.describe Alexa::Response do
  subject(:response) { described_class.new }

  describe '#to_json' do
    it 'returns a minimal JSON response' do
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