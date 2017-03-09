# Alexa 2: Fact-checking

We’re going to build a fact-checking mechanism that allows users to research for information like this:

> Alexa, ask NumberFacts to tell me a trivia fact about 42.
> Alexa, ask NumberFacts to tell me a math fact about 5.

We’ll be able to supply:
- a number (any number!), and 
- a fact type, 
and receive an interesting fact about that number, constrained to that fact type.

## 1. Scaffolding a new skill

By the end of this section, we’ll be able to interact with a simplified version of our final feature:

> Alexa, ask NumberFacts about 42.

Alexa should respond with a trivia fact about the number **42**. Later, we’ll build on this feature to add trivia responses for all sorts of numbers.

Sign in to the [Alexa Developer Portal](https://developer.amazon.com/alexa), and set up a new skill. Let’s call it **NumberFacts**, with an invocation name of **NumberFacts**:

![](Screen%20Shot%202017-03-09%20at%2012.59.52.png)

> You could edit the skill you set up in module 1, or practice making a new one.

Let’s start by defining a minimal Intent Schema, with a single Intent:

  {
    "intents": [
      {
        "intent": "NumberFacts"
      }
    ]
  }

And a simple Utterance for this:

  NumberFact about forty two

Let’s check that this works, by setting up an HTTPS-tunnelled Sinatra application just as we did in module 1. Our Sinatra code:

  require 'sinatra'
  require 'json'
  
  post '/' do  
    { 
      version: "1.0",
      response: {
        outputSpeech: {
            type: "PlainText",
            text: "The number 42 is pretty cool."
          }
      }
    }.to_json
  end

Great! Once we start the server and provide our ngrok Endpoint to our Skill, we should be able to use the Service Simulator to test a basic interaction. When we ask:

> Alexa, ask NumberFacts about 42

Alexa should respond with:

> The number 42 is pretty cool.

 Now, let’s upgrade our Ruby code to give us an interesting fact about the number 42.

Let’s use the [Numbers API](http://numbersapi.com/)to grab an interesting fact about the number 42:

  require 'sinatra'
  require 'json'
  # Since we're making a call to an external API,
  # we need Ruby's Net::HTTP library.
  require 'net/http'
  
  post '/' do  
    # First, we encode the Numbers API as a URI
    number_facts_uri = URI("http://numbersapi.com/42")
    # Then we make a request to the API
    number_fact = Net::HTTP.get(number_facts_uri)
  
    { 
      version: "1.0",
      response: {
        outputSpeech: {
            type: "PlainText",
            # We provide the fact we received as
            # plain text in our response to Amazon.
            text: number_fact
          }
      }
    }.to_json
  end

Head to the Service Simulator and see that you can now make a request to NumberFacts for random trivia about the number 42. This is a great start! But what about trivia for other numbers?

## 2. Using built-in Slots to pass parameters to our application

In section 1, our invocation contained zero parameters – we just asked NumberFacts to tell us about ’42’. If we asked it to tell us about any other number, Alexa will just tell us about 42.

We’d like to receive trivia facts for all sorts of numbers. We want to be able to ask:

> Alexa, ask NumberFacts about \<number\>

Where `<number>` is any number. We want to receive a response concerning that number, and that number only.

To do this, we need to provide a parameter to our Intent, and to our Utterance. In Alexa’s terminology, we provide parameters as **Slots**.

Let’s update our Intent Schema with a new Slot, for a number:

  {
    "intents": [
      {
        "intent": "NumberFact",
        "slots": [
          {
            "name": "Number",
            "type": "AMAZON.NUMBER"
          }
        ]
      }
    ]
  }

- `slots` is an array of JSON objects, each with:
  - a `name`: so we can reference the Slot in the Utterances
  - a `type`, which limits the possible return values a Slot can have.


We’ve chosen the `AMAZON.NUMBER` type, which will convert any spoken numbers to digits:

> Alexa, ask NumberFacts about fifteen

Becomes

> Alexa, ask NumberFacts about 15

There are many [built-in Slot types](https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/slot-type-reference). You can also define additional types (we’ll do this in the next section).

Let’s update our Utterances to handle this new Slot:

  NumberFacts about {Number}

Before we change any Ruby code, let’s observe the incoming request from Amazon’s Service Simulator using `puts` in Sinatra. Notice the Slot value passed in the request:

  "intent" => {
    "name" => "NumberFact", 
    "slots" => { 
    "Number" => { 
      "name" => "Number", 
      "value" => "4"
      }
    }
  }

Instead of always requesting trivia for the number 42, let’s grab the Slot value out of Amazon’s request and pass that to the Numbers API:

  require 'sinatra'
  require 'json'
  require 'net/http'
  
  post '/' do  
    # Grab the slot value from the incoming request
    number = JSON.parse(request.body.read)["request"]["intent"]["slots"]["Number"]["value"]
  
    # Pass that number to the numbers api
    number_facts_uri = URI("http://numbersapi.com/#{ number }")
    number_fact = Net::HTTP.get(number_facts_uri)
  
    { 
      version: "1.0",
      response: {
        outputSpeech: {
            type: "PlainText",
            text: number_fact
          }
      }
    }.to_json
  end

Let’s test this in the Service Simulator. If everything is working correctly, we’ll be able to provide an arbitrary number to our NumberFacts skill, and receive trivia about that number. Great!

Now, let’s make one final upgrade and ask for facts of a specific type, too.

## 3. Using custom slots

So far, we can ask Alexa:

> Alexa, ask NumberFacts about \<number\>

Where `<number>` is any number. We’ll get back an interesting piece of trivia about any given number.

However, there are different sorts of facts. We’d like to be able to ask:

> Alexa, ask NumberFacts to tell me a \<fact type\> fact about \<number\>

Where `<fact type>` is either a ‘trivia’ fact or a ‘math’ fact. Because we’re passing another parameter to our Intent, we’ll need to define another Slot. However, where the built-in `AMAZON.NUMBER` slot restricted us to numbers only, there are no built-in Slots that will restrict us to ‘trivia’ or ‘math’. We have to make our own.

Head to the Interaction Model pane in the Alexa Skills Developer Console, and add a new Custom Slot type, called `FACT_TYPE`. There are two Values for this Custom Slot type: `trivia` and `math`. They must be provided separated by a pipe (`|`), like so:

  trivia | math

Once we’ve provided our Custom Slot type, we can go ahead and reference it in our Intent:

  {
    "intents": [
      {
        "intent": "NumberFact",
        "slots": [
          { 
            "name": "Number",
            "type": "AMAZON.NUMBER"
          },
          {
            "name": "FactType",
            "type": "FACT_TYPE"
          }
        ]
      }
    ]
  }

And in our Utterance:

  NumberFact tell me a {FactType} fact about {Number}

In our Sinatra application, we can grab the fact type similarly to how we did the number, and pass it directly to the Numbers API:

  require 'sinatra'
  require 'json'
  require 'net/http'
  
  post '/' do 
    parsed_request = JSON.parse(request.body.read)
  
    number = parsed_request["request"]["intent"]["slots"]["Number"]["value"]
    fact_type = parsed_request["request"]["intent"]["slots"]["FactType"]["value"]
  
    number_facts_uri = URI("http://numbersapi.com/#{ number }/#{ fact_type }")
    number_fact = Net::HTTP.get(number_facts_uri)
  
    { 
      version: "1.0",
      response: {
        outputSpeech: {
            type: "PlainText",
            text: number_fact
          }
      }
    }.to_json
  end

Let’s test in the Service Simulator: 
> Alexa ask NumberFacts to tell me a math fact about 17.

It works!

> Notice how entering a strange Utterance, e.g. ‘…about 12 math’ still invokes the Intent. As a Ruby exercise, try to handle poorly-formed Utterances gracefully via the Sinatra application.