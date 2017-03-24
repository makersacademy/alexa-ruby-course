require 'json'

module Alexa
  class Response
    def initialize(output_text = "Hello World", session_attributes = {})
      @output_text = output_text
      @session_attributes = session_attributes
    end

    def to_json
      response = Hash.new
      response[:version] = "1.0"
      response[:sessionAttributes] = @session_attributes unless @session_attributes.empty?
      response[:response] = { 
        outputSpeech: {
          type: "PlainText",
          text: @output_text
        }
      }

      response.to_json
    end
  end
end