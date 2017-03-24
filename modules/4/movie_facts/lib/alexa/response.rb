require 'json'

module Alexa
  class Response
    def initialize(output_text = "Hello World", session_attributes = {}, end_session = false)
      @output_text = output_text
      @session_attributes = session_attributes
      @end_session = end_session
    end

    def to_json
      response = Hash.new
      response[:version] = "1.0"
      response[:sessionAttributes] = @session_attributes unless @session_attributes.empty?

      response[:response] = Hash.new
      response[:response][:outputSpeech] = Hash.new
      response[:response][:outputSpeech][:type] = "PlainText"
      response[:response][:outputSpeech][:text] = @output_text
      
      response[:response][:shouldEndSession] = @end_session if @end_session

      response.to_json
    end
  end
end