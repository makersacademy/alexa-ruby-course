require './lib/alexa/request'
require './lib/alexa/response'

module Alexa
  class Handlers
    @@intents = {}

    def initialize(request, response)
      @request  = request
      @response = response
    end

    def handle
      instance_eval &@@intents[request.intent_name]
    end

    class << self
      def intent(intent_name, &block)
        @@intents[intent_name] = block
      end

      def handle(request)
        new(Alexa::Request.new(request), Alexa::Response).handle
      end
    end

    private

    attr_reader :request, :response
  end
end