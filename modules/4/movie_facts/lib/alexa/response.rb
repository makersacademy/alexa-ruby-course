require 'json'

module Alexa
  class Response < Hash
    def initialize(output_text, session_attributes, end_session)
      set_version
      set_session_attributes(session_attributes)
      set_response(output_text, end_session)
    end

    def self.build(output_text = "Hello World", session_attributes = {}, end_session = false)
      new(output_text, session_attributes, end_session).to_json
    end

    private

    def set_version
      self[:version] = "1.0"
    end

    def set_session_attributes(session_attributes)
      self[:sessionAttributes] = session_attributes unless session_attributes.empty?
    end

    def set_response(output_text, end_session)
      self[:response] = Hash.new
      self[:response][:outputSpeech] = Hash.new
      self[:response][:outputSpeech][:type] = "PlainText"
      self[:response][:outputSpeech][:text] = output_text
      self[:response][:shouldEndSession] = end_session if end_session
    end
  end
end