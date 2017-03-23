require 'json'

module Alexa
  class Response
    def initialize(output_text = "Hello World", session_attributes = {})
      @output_text = output_text
      @session_attributes = session_attributes
    end

    def to_json
      { 
        version: "1.0",
        response: {
          outputSpeech: {
              type: "PlainText",
              text: @output_text
            }
        }
      }.to_json
    end
  end
end