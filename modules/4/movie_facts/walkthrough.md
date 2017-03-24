# Alexa 4: Modelling Alexa using Object-Oriented Ruby

So far, we've constructed three simple applications using a scripting approach. During this module, we'll extract some Objects from our applications. These objects will represent some of the concepts we've encountered so far, and help us to work with them in future, more complex applications.

By the end of this module, you will have extracted a well-tested basic framework for working with Alexa using Sinatra and Ruby. This framework will speed up our subsequent development by _abstracting_ some of the messy JSON manipulation we've been doing in our scripts so far. You'll cover:

- Modelling OO Principles in Ruby
- Test-Driving an OO refactor

As we go, we'll be sticking closely to a step-by-step [**Red, Green, Refactor**](http://blog.cleancoder.com/uncle-bob/2014/12/17/TheCyclesOfTDD.html) cycle.

We will start by pulling objects from module 1: Hello World, then we will extend our framework using module 2: Number Facts. Finally, we'll extend our framework using module 3: Conversational Movie Facts.

## Refactoring Hello World: Pulling out a Response object

In our first module, Hello World, we wound up with a simple Sinatra application. This application responded to any POST requests to the index route ('/') with some JSON:

```ruby
require 'sinatra'
require 'json'

post '/' do  
  { 
    version: "1.0",
    response: {
      outputSpeech: {
          type: "PlainText",
          text: "Hello World"
        }
    }
  }.to_json
end
```

This JSON response looks like it has meaning within our domain: in fact, we could probably name it. Let's try:

> This JSON is about the Alexa Response.

Since we can name it, let's pull it into an object. This has the effect of being able to reason about our code in chunks, rather than as a messy batch of JSON. Once we're finished, we'll be able to reason about Alexa Responses. The design we're headed for will probably look something like this:

```ruby
# inside server.rb
require 'sinatra'

post '/' do
  Alexa::Response.build
end
```

### Setting up RSpec

We'll start with a test. Let's use the Ruby testing framework [RSpec](http://rspec.info/).

> If you're not familiar with Test-Driven Development, now's a great time to get started! As we extract objects, we'll be encountering some simple and intermediate uses of Test-Driven Development.

- In your 'Hello World' application, add `gem 'rspec'` to your project Gemfile.
- From the command-line, run `bundle` to install RSpec to your project.
- From the command-line, run `rspec --init` to initialize RSpec within your project.
- Create a `/lib` folder in the root of your 'Hello World' application directory.

### Writing and passing the first test

Our first test is going to be simple: it'll test that a class named `Alexa::Response` exists.

```ruby
# in spec/alexa_response_spec.rb
require 'alexa/response'

RSpec.describe Alexa::Response do
end
```

We can run our RSpec tests via the command-line, using `rspec`. We get an error, because the `require` statement at the top of our test cannot find a file at the following path: `lib/alexa/response.rb` (RSpec will automatically try to load `require`d files from the `/lib` directory).

We can solve this problem by creating a file with that name, in that location, and defining our class:

```ruby
# in lib/alexa/response.rb
module Alexa
  class Response
  end
end
```

> We've _namespaced_ the `Response` class within an `Alexa` namespace, so we'll always be referencing the `Response` class like this: `Alexa::Response`. We've done this to avoid collisions with other `Response` classes that might be hanging around in other applications we try to use this class within.

Running `rspec` from the command-line, we get our first pass – our first Green. 

### Testing our intended design

Now, let's try to build a method that reflects the interface we're planning to implement. To remind us what that is, we're hoping to head for:

```ruby
# inside server.rb
require 'sinatra'

post '/' do
  Alexa::Response.build
end
```

Our next test therefore needs to test this proposed interface. Let's write a test that expects the JSON (the 'Minimal Response') we currently have in `server.rb`. We want this to be returned whenever we call `Alexa::Response.build`:

```ruby
# inside alexa_response_spec.rb

RSpec.describe Alexa::Response do
  describe '.build' do
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

      expect(Alexa::Response.build).to eq minimal_response
    end
  end
end
```

Our final line, the **expectation**, reads like a summary of the paragraph above:

> Expect that when we 'build' an Alexa Response (with no further information), we get the Minimal Response.

Run the test using `rspec` on the command-line. It will fail, because our current implementation of the `Alexa::Response` class (in `lib/alexa/response.rb`) doesn't yet implement the class method `.build`.

### Racing to Green with our design

In Test-Driven Development, there is a strong mantra of 'Racing to Green'. That is: we should take the simplest steps possible to reach a 'Green' test.

Given that we are currently failing because we haven't implemented a `.build` method on `Alexa::Response`, let's implement that:

```ruby
# in lib/alexa/response.rb
module Alexa
  class Response
    def self.build
    end
  end
end
```

Run the test again from the command-line. Now we have a different failure: We have a `.build` method alright, but it's not returning the Minimal Response. Instead, it's returning `nil`. Let's implement the quickest Race to Green we can, by simply pasting the Minimal Response into the method:

```ruby
# in lib/alexa/response.rb
require 'json'

module Alexa
  class Response
    def self.build
      {
        version: "1.0",
        response: {
          outputSpeech: {
            type: "PlainText",
            text: "Hello World"
          }
        }
      }.to_json
    end
  end
end
```

Our test now passes. We can replace the JSON in `server.rb` with our new design, and test the 'Hello World' application in the Service Simulator: it works!

### Refactoring

It feels strange to have a class with only one method, and no real 'state' to speak of – there's no initializer, and we don't do anything with any stored information. Plus, our method name 'build' implies that we're going to be using the Builder Pattern.

The last step of the Red-Green-Refactor cycle is a **Refactor** step. Because we have thorough tests for outcomes (in `spec/alexa_response_spec.rb`), we're free to play around with our implementation code (in `lib/alexa/response.rb`).

> You might spot a better refactor at this point, or decide it's not worth it. In that case, feel free to move on!

Here are some things worth noticing that guided my refactor here:

- An 'Alexa Response' is a kind of Hash.
- When we 'build' an Alexa Response, we transform it into some JSON.
- Later, we know we're going to need to supply all sorts of variable information to this building process.

I decided to inherit the `Alexa::Response` class from Ruby's built-in `Hash`, and to construct the Hash in a procedural fashion. I felt this gave us optimised the JSON response for change later on, because we'd only have to make changes in simple locations to pass variable data into the object:

```ruby
# in lib/alexa/response.rb
require 'json'

module Alexa
  class Response < Hash
    def initialize
      # in the initializer, we build the response procedurally
      self[:version] = "1.0"
      self[:response] = Hash.new
      self[:response][:outputSpeech] = Hash.new
      self[:response][:outputSpeech][:type] = "PlainText"
      self[:response][:outputSpeech][:text] = "Hello World"
    end

    def build
      # in the builder, we convert the response from the initializer to JSON
      new.to_json
    end
  end
end
```

This passes the tests, and feels simple to extend with some variable data later on.

We're done with Hello World: let's move on to Number Facts.

## Refactoring Number Facts: Extending the Response, and pulling out a Request object

In our second module, Number Facts, we would up with another simple Sinatra Application. In addition to returning a JSON response to an Alexa Request, we handled variable data via Slots. In this section, we'll extend our Response to handle such variable data, and pull out a Request object that gives us easier access to Slots.

Here is our Sinatra application at the end of module 2:

```ruby
# inside server.rb of 'Number Facts'
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
```

### Bringing in RSpec and our existing framework

First thing's first: let's copy-paste the contents of our `/lib` and `/spec` directories from our refactored 'Hello World' application into our 'Number Facts' application. Also, let's install and initialize RSpec as we did before:

- Add RSpec to the Gemfile,
- Install dependencies using Bundler, and
- Initialize RSpec.

### Extending the Response with a Number Fact

The final 8 lines of our `server.rb` application are, again, an Alexa Response. So, it stands to reason that we should be able to use the object we extracted from our Hello World application instead of this messy JSON. And we _almost_ can – except that our current implementation of `Alexa::Response` can only return response text of "Hello World". Our 'Number Facts' application requires that we send an Alexa Response with a number fact.

Let's start by thinking about the ideal interface we'd like at the end of our POST route in `server.rb`. The following feels pretty good to me:

```ruby
# inside server.rb, with some omissions for brevity
...
  number_fact = Net::HTTP.get(number_facts_uri)

  Alexa::Response.build(number_fact)
end
```

First, let's write a test for the kind of JSON response we expect to receive from this interface:

```ruby
# in spec/alexa/response.rb
require 'alexa/response'

RSpec.describe Alexa::Response do
  describe '.build' do
    it 'returns a JSON response with a custom string if provided' do
      expected_response = {
        version: "1.0",
        response: {
          outputSpeech: {
            type: "PlainText",
            text: "Custom String"
          }
        }
      }.to_json

      expect(Alexa::Response.build("Custom String")).to eq expected_response
    end

    it 'returns a minimal JSON response otherwise' do
      # this is where our previous test goes
      # as we still want to be able to call
      # Alexa::Response.build (with no parameters)
      # and have that return the minimal response
    end
  end
end
```

> Check over our new expectation. Does it read correctly? "Expect that when we 'build' an Alexa Response (with a string), we get the Minimal Response with that given string." That feels like a good summary of what we want to happen; let's proceed!

Run the test – it fails. Now, we have to Race to Green. Here's my implementation:

```ruby
# in lib/alexa/response.rb
require 'json'

module Alexa
  class Response < Hash
    def initialize(response_text)
      self[:version] = "1.0"
      self[:response] = Hash.new
      self[:response][:outputSpeech] = Hash.new
      self[:response][:outputSpeech][:type] = "PlainText"

      # Exchange our hard-coded 'Hello World' for the variable response_text
      self[:response][:outputSpeech][:text] = response_text
    end

    def build(response_text)
      new(response_text).to_json
    end
  end
end
```

Our second test passes! However, our initial test fails. It fails because we can no longer call `.build` without providing a string. However, we still want to be able to call `Alexa::Response.build` – without any parameters – and return the Minimal Response. So, we need to set a default value for the string we pass to `.build`:

```ruby
# in lib/alexa/response.rb, with some omissions for brevity

def build(response_text = "Hello World")
  new(response_text).to_json
end
```

Now, when we run our tests, they both pass.

Let's use our new, upgraded `Alexa::Response` object in Numbers Facts' `server.rb`:

```ruby
# inside server.rb of 'Number Facts'
require 'sinatra'
require 'json'
require 'net/http'

post '/' do 
  parsed_request = JSON.parse(request.body.read)
  number = parsed_request["request"]["intent"]["slots"]["Number"]["value"]
  fact_type = parsed_request["request"]["intent"]["slots"]["FactType"]["value"]

  number_facts_uri = URI("http://numbersapi.com/#{ number }/#{ fact_type }")
  number_fact = Net::HTTP.get(number_facts_uri)

  Alexa::Response.build(number_fact)
end
```

Testing in the Service Simulator, we can see that our refactor has been successful: functionality has not been affected by our tidying of the code.

### Getting cleaners access to Slots using a Request object

The first three lines of Number Facts' `server.rb` POST route are unpleasant to read. They:

- Parse the incoming request into a Hash,
- Extract a slot value from that Hash,
- Extract another slot value from the Hash.

It feels like there is an object which lurks behind those three behaviours. It may have meaning in our domain. Like we did with `Alexa::Response`, let's try naming it:

> These lines are about the Alexa Request.

Again: since we can name it, let's pull it into an object. We start with an intended interface for these three lines:

```ruby
# inside server.rb, with some omissions for brevity
post '/' do
  alexa_request = Alexa::Request.new(request)
  number = alexa_request.slot_value("Number")
  fact_type = alexa_request.slot_value("FactType")
```

That reads more pleasantly, as well as framing words like "slot", which have so far existed only as strings in our scripts, as meaningful domain terms written into method names.

> Wrapping the Sinatra `request` object directly means we're going to have to mock its behaviour in our tests.

Let's write a test for this kind of behaviour:

```ruby
# in spec/alexa_request_spec.rb
require 'alexa/request'

RSpec.describe Alexa::Request do
  describe '#slot_value' do
    it 'returns the value for a specified slot' do
      # Let's use a sample of some JSON
      # taken from the Service Simulator
      request_json = {
        "request": {
          "type": "IntentRequest",
          "intent": {
            "name": "IntentName",
            "slots": {
              "SlotName": {
                "name": "SlotName",
                "value": "10"
              }
            }
          }
        }
      }.to_json

      # Now we must mock the behaviour of the
      # incoming Sinatra request, with a #body
      # method that yields a StringIO containing
      # the JSON we are ultimately dealing with
      sinatra_request = double("Sinatra::Request", body: StringIO.new(request_json))

      expect(Alexa::Request.new(sinatra_request).slot_value("SlotName")).to eq "10"
    end
  end
end
```

Three important things are happening in this test:

- Set up some sample JSON (from the Service Simulator)
- Wrap that JSON inside a mocked-up Sinatra `request` entity
- Expect that an Alexa Request wrapping this Sinatra `request` will have a slot called `'SlotName'` with a value of `"10"`.

Let's go ahead and implement this.

```ruby
# inside lib/alexa/request.rb
require 'json'

module Alexa
  class Request
    def initialize(sinatra_request)
      # Since we probably want to do more with this request,
      # we'll store the request as a hash internally
      @request = JSON.parse(sinatra_request.body.read)
    end

    def slot_value(slot_name)
      # this is essentially copy-pasted from server.rb
      @request["request"]["intent"]["slots"][slot_name]["value"]
    end
  end
end
```

Running `rspec` from the command-line, our tests pass. We can now use this new object in `server.rb`:

```ruby
# inside server.rb, with some omissions for brevity
post '/' do
  alexa_request = Alexa::Request.new(request)

  number_facts_uri = URI("http://numbersapi.com/#{ alexa_request.slot_value("Number") }/#{ alexa_request.slot_value("FactType") }")
  number_fact = Net::HTTP.get(number_facts_uri)

  Alexa::Response.build(number_fact)
end
```

### OPTIONAL: Pulling out a Number Fact

While we're working with the Number Facts application, let's tidy up some of the functionality concerned with 'Number Facts'. The first step feels clear: pulling out a `NumberFact` object. 

We can start by using the [Extract Method](https://sourcemaking.com/refactoring/extract-method) refactoring technique inside `server.rb` to isolate functionality related to Number Facts only:

```ruby
# inside server.rb, with some omissions for brevity

post '/' do
  alexa_request = Alexa::Request.new(request)

  number_fact = fetch_number_fact(alexa_request.slot_value("Number"), alexa_request.slot_value("FactType"))

  Alexa::Response.build(number_fact)
end

def fetch_number_fact(number, fact_type)
  number_facts_uri = URI("http://numbersapi.com/#{ number }/#{ fact_type }")
  number_fact = Net::HTTP.get(number_facts_uri)
end
```

Clearly, this method is suited for us to use the [Extract Class](https://sourcemaking.com/refactoring/extract-class) refactoring technique. Let's write a test for a `NumberFact` object, mocking the `Net::HTTP` library (and injecting it) to avoid making any external calls:

```ruby
# inside spec/number_fact_spec.rb
require 'number_fact'

RSpec.described NumberFact do
  describe '#text' do
    it 'returns a fact for a given number and fact type as plain text' do
      number_fact_text = "3 is the number of spatial dimensions we perceive our universe to have."
      client = double("Net::HTTP", get: number_fact_text)
      number_fact = described_class.new("3", "trivia", client)

      expect(number_fact.text).to eq number_fact_text
    end
  end
end
```

We can pull the code we extracted using Extract Method into a `NumberFact` class to pass this test:

```ruby
# in lib/number_fact.rb

class NumberFact
  attr_reader :text

  # we need to inject our double client to mock the HTTP call
  def initialize(number, fact_type, client = Net::HTTP)
    number_facts_uri = URI("http://numbersapi.com/#{ number }/#{ fact_type }")
    @text = client.get(number_facts_uri)
  end
end
```

Our test passes, and we can refactor `server.rb` to use our new `NumberFact` object:

```ruby
# in server.rb
require 'sinatra'
require './lib/alexa/request'
require './lib/alexa/response'
require './lib/number_fact'

post '/' do
  alexa_request = Alexa::Request.new(request)
  number_fact = NumberFact.new(alexa_request.slot_value("Number"), alexa_request.slot_value("FactType"))
  Alexa::Response.build(number_fact.text)
end
```

If we want to golf this down further, we could move the slot value extraction into the `NumberFact` class (tests omitted for brevity):

```ruby
# in lib/number_fact.rb, with some omissions for brevity
class NumberFact
  ...

  def self.build(alexa_request, client = Net::HTTP)
    new(alexa_request.slot_value("Number"), alexa_request.slot_value("FactType"))
  end
end
```

This would refactor `server.rb` further to the far more expressive:

```ruby
# inside server.rb, with some omissions for brevity
post '/' do
  number_fact = NumberFact.build(Alexa::Request.new(request))
  Alexa::Response.build(number_fact.text)
end
```

We're done with Number Facts: let's move on to our 'Movie Facts' skill.

## Refactoring Movie Facts: extracting the Session

In our third module, Movie Facts, we would up with a reasonably simple Sinatra application. Like Number Facts, Movie Facts handled JSON responses with variable data using Slots, and querying an external API. In addition, Movie Facts used the Session and Session Attributes to engage users in a multi-stage process for making queries about movies. In this section, we'll extend our Request and Response objects to handle reading from and writing to the Session.

Here's our Sinatra application at the end of module 3:

```ruby
require 'sinatra'
require 'json'
require 'imdb'

post '/' do 
  parsed_request = JSON.parse(request.body.read)
  session = parsed_request["session"]
  this_is_the_first_request = session["new"]

  if parsed_request["request"]["intent"]["name"] == "ClearSession"
    return {
      version: "1.0",
      response: {
        outputSpeech: {
          type: "PlainText",
          text: "OK, what movie would you like to know about?"
        },
        shouldEndSession: true
      }
    }.to_json
  end

  if this_is_the_first_request
    requested_movie = parsed_request["request"]["intent"]["slots"]["Movie"]["value"]
    movie_list = Imdb::Search.new(requested_movie).movies
    movie = movie_list.first

    return { 
      version: "1.0",
      sessionAttributes: {
        movieTitle: requested_movie
      },
      response: {
        outputSpeech: {
            type: "PlainText",
            text: movie.plot_synopsis
          }
      }
    }.to_json
  end

  movie_title = session["attributes"]["movieTitle"]
  movie_list = Imdb::Search.new(movie_title).movies
  movie = movie_list.first

  role = parsed_request["request"]["intent"]["slots"]["Role"]["value"]

  if role == "directed"
    response_text = "#{movie_title} was directed by #{movie.director.join}"
  end

  if role == "starred in"
    response_text = "#{movie_title} starred #{movie.cast_members.join(", ")}"
  end

  return {
    version: "1.0",
    sessionAttributes: {
      movieTitle: movie_title
    },
    response: {
      outputSpeech: {
        type: "PlainText",
        text: response_text
      }
    }
  }.to_json
end
```

This is pretty painful to read! Hopefully we'll be able to make it significantly more readable with our framework.

### Bringing in RSpec and our existing framework

Once again, let's copy-paste the contents of our `/lib` and `/spec` directories from our refactored 'Number Facts' application into our 'Movie Facts' application. Also, let's install and initialize RSpec as we did before:

- Add RSpec to the Gemfile,
- Install dependencies using Bundler, and
- Initialize RSpec.

### Extending the Response with Session Attributes

Much of our Movie Facts application is concerned with handling the Session. In particular, we have three clear rules:

- If the user asks to clear the session, start a new session.
- If the user is speaking for the first time, respond with the plot synopsis for the movie they ask for.
- If the user is not speaking for the first time, read which movie they were talking about from the session and respond with more information about that movie.

All of these rules involve reading to or writing from the Session. A quick win for us will be to extract Session Attributes into our Response, so we can set them easily. Our ideal interface for the last 11 lines of JSON in the POST request would be as follows:

```ruby
# inside server.rb, with some omissions for brevity

Alexa::Response.build(response_text, { movieTitle: movie_title })
```

Let's write a test for this extra parameter, which we use to set the Session Attributes in the Alexa Response:

```ruby
# in spec/alexa_response_spec.rb, with some omissions for brevity

describe '.build' do
  it 'returns a JSON response with session data if provided' do
    expected_response = {
      version: "1.0",
      sessionAttributes: {
        sessionKey: "Session Value"
      },
      response: {
        outputSpeech: {
          type: "PlainText",
          text: "Hello World"
        }
      }
    }.to_json

    session_response = Alexa::Response.build("Hello World", { sessionKey: "Session Value" })
    expect(session_response).to eq expected_response
  end
end
```

It's relatively easy for us to implement this, given that we're building our Response hash procedurally:

```ruby
# in lib/alexa/response.rb, with some omissions for brevity
module Alexa
  class Response < Hash
    def initialize(response_text, session_attributes)
      self[:version] = "1.0"
      self[:sessionAttributes] = session_attributes
      self[:response] = Hash.new
      ...
    end

    def build(response_text = "Hello World", session_attributes = {})
      new(response_text, session_attributes).to_json
    end
  end
end
```

Running our tests using `rspec` from the command-line, we get a failure: our previous test for the Minimal Response, which doesn't include any session attributes, now includes a `sessionAttributes` key. To fix this, we need to make sure we only add session attributes to the response when they are non-empty:

```ruby
# in lib/alexa/response.rb, with some omissions for brevity
module Alexa
  class Response < Hash
    def initialize(response_text, session_attributes)
      ...
      self[:sessionAttributes] = session_attributes unless session_attributes.empty?
      ...
    end
  end
end
```

Our tests pass once again! Now let's replace those lines in `server.rb` with our upgraded `Alexa::Response`:

```ruby
# in server.rb
```

