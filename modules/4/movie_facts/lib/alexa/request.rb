require 'json'

module Alexa
  class Request
    def initialize(original_request)
      @request = JSON.parse(original_request.body.read)
    end

    def slot_value(slot_name)
      @request["request"]["intent"]["slots"][slot_name]["value"]
    end

    def new_session?
      @request["session"]["new"]
    end

    def intent_name
      @request["request"]["intent"]["name"]
    end
  end
end