require 'json'

module Alexa
  class Response
    def initialize(output_text = "Hello World")
      @output_text = output_text
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