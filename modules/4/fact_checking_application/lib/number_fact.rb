require 'net/http'

class NumberFact
  attr_reader :text

  def initialize(number, fact_type, client = Net::HTTP)
    number_facts_uri = URI("http://numbersapi.com/#{ number }/#{ fact_type }")
    @text = client.get(number_facts_uri)
  end
end