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

    def self.build
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

    def self.build(response_text)
      new(response_text).to_json
    end
  end
end
```

Our second test passes! However, our initial test fails. It fails because we can no longer call `.build` without providing a string. However, we still want to be able to call `Alexa::Response.build` – without any parameters – and return the Minimal Response. So, we need to set a default value for the string we pass to `.build`:

```ruby
# in lib/alexa/response.rb, with some omissions for brevity

def self.build(response_text = "Hello World")
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

  if parsed_request["request"]["intent"]["name"] == "AMAZON.StartOverIntent"
    return {
      version: "1.0",
      response: {
        sessionAttributes: {},
        outputSpeech: {
          type: "PlainText",
          text: "OK, what movie would you like to know about?"
        }
      }
    }.to_json
  end

  if parsed_request["request"]["intent"]["name"] == "MovieFacts"
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
            text: "#{movie.plot_synopsis.slice(0, 140)}. You can ask who directed that, or who starred in it."
          }
      }
    }.to_json
  end

  if parsed_request["request"]["intent"]["name"] == "FollowUp"
    movie_title = parsed_request["session"]["attributes"]["movieTitle"]
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
          text: "#{response_text.slice(0, 140)}. Ask who starred in it, or start over."
        }
      }
    }.to_json
  end
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

- If the user asks to 'start over', clear the Session Attributes.
- If the user asks about a movie, respond with the plot synopsis for that movie, and write that movie to the session.
- If the user asks a follow-up question, read which movie they were talking about from the session and respond with more information about that movie.

All of these rules involve reading to or writing from the Session. A quick win for us will be to extract _the setting of Session Attributes_ into our Response, so we can set them easily. We can target all three rules in our code with this extraction.

Our ideal interface for the response to the `AMAZON.StartOverIntent` could be as follows:

```ruby
if parsed_request["request"]["intent"]["name"] == "AMAZON.StartOverIntent"
  Amazon::Response.build(movie.plot_synopsis, {})
end
```

Our ideal interfact for the response to the `MovieFacts` Intent would be as follows:

```ruby
# inside server.rb, with some omissions for brevity

if parsed_request["request"]["intent"]["name"] == "MovieFacts"
  requested_movie = parsed_request["request"]["intent"]["slots"]["Movie"]["value"]
  movie_list = Imdb::Search.new(requested_movie).movies
  movie = movie_list.first

  Alexa::Response.build(movie.plot_synopsis, { movieTitle: movie.title })
end
```

Also, our ideal interface for the last 11 lines of JSON in the POST request (handling the `FollowUp` Intent) would be as follows:

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

    def self.build(response_text = "Hello World", session_attributes = {})
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
require 'sinatra'
require 'json'
require 'imdb'

post '/' do 
  parsed_request = JSON.parse(request.body.read)

  if parsed_request["request"]["intent"]["name"] == "AMAZON.StartOverIntent"
    return Alexa::Response.build("OK, what movie would you like to know about?", {})
  end

  if parsed_request["request"]["intent"]["name"] == "MovieFacts"
    requested_movie = parsed_request["request"]["intent"]["slots"]["Movie"]["value"]
    movie_list = Imdb::Search.new(requested_movie).movies
    movie = movie_list.first

    return Alexa::Response.build(movie.plot_synopsis, { movieTitle: movie.title })
  end

  if parsed_request["request"]["intent"]["name"] == "FollowUp"
    movie_title = parsed_request["session"]["attributes"]["movieTitle"]
    movie_list = Imdb::Search.new(movie_title).movies
    movie = movie_list.first

    role = parsed_request["request"]["intent"]["slots"]["Role"]["value"]

    if role == "directed"
      response_text = "#{movie_title} was directed by #{movie.director.join}"
    end

    if role == "starred in"
      response_text = "#{movie_title} starred #{movie.cast_members.join(", ")}"
    end

  Alexa::Response.build(response_text, { movieTitle: movie_title })
end
```

This feels much more readable! Remember, though, that users should also be able to _end_ the Session at certain points. Let's make sure they can do that now.

### Extending the Response to End the Session

We haven't yet extended our `Alexa::Response` object with the capacity to end a Session. Similarly to how we implemented `Alexa::Response`'s ability to manage Session Attributes, let's imagine how this design could work:

```ruby
# inside an imaginary future server.rb

if parsed_request["request"]["intent"]["name"] == "RestartSession"
  return Alexa::Response.build("Goodbye", {}, true)
end
```

> This design is starting to feel a little unreadable: it's not immediately clear what an empty hash and boolean 'true' have to do with an `Alexa::Response`. We'll come to that during the refactor step.

Here is a test for the new `start_over` boolean parameter:

```ruby
# inside spec/alexa_response_spec.rb

it 'returns a JSON response that "starts over" by clearing the Session Attributes if provided' do
  expected_response = {
    version: "1.0",
    sessionAttributes: {},
    response: {
      outputSpeech: {
        type: "PlainText",
        text: "Hello World"
      }
    }
  }.to_json

  start_over_response = described_class.build(start_over: true)
  expect(start_over_response).to eq expected_response
end
```

To pass this test, we can easily insert another procedure into our hash construction in `Alexa::Response`:

```ruby
# inside lib/alexa/response.rb, with some omissions for brevity

module Alexa
  class Response
    def initialize(response_text, session_attributes, start_over)
      ...
      response[:response][:shouldEndSession] = end_session if end_session
    end
  end
end
```

Our test passes! However, this long list of parameters to `Alexa::Response`s is becoming hard to understand. Let's refactor.

### Refactoring for readability

We've improved the design of our session-start-over response somewhat:

```ruby
# inside server.rb, with some omissions for brevity

if parsed_request["request"]["intent"]["name"] == "AMAZON.StartOverIntent"
  return Alexa::Response.build("OK, what movie would you like to know about?", {})
end
```

And we've improved the design of ending sessions:

```ruby
# inside an imaginary future server.rb

if parsed_request["request"]["intent"]["name"] == "RestartSession"
  return Alexa::Response.build("Goodbye", {}, true)
end
```

While this is clearly an improvement to the current mess of JSON construction, we can do better. From reading the parameter list given to `.build`, it's not immediately clear what an empty hash (`{}`) and boolean `true` have to do with an `Alexa::Response`. The following design is much clearer, as well as enshrining some domain concepts:

```ruby
# inside server.rb, with some omissions for brevity

if parsed_request["request"]["intent"]["name"] == "AMAZON.StartOverIntent"
  response_text = "OK, what movie would you like to know about?"
  return Alexa::Response.build(response_text: response_text, start_over: true)
end

if parsed_request["request"]["intent"]["name"] == "MovieFacts"
  ... retrieve the movie record ...
  return Alexa::Response.build(response_text: movie.title, session_attributes: { movieTitle: movie.title })
end
```

And, in our imaginary future scenario where we'd want to end the session:

```ruby
if parsed_request["request"]["intent"]["name"] == "EndSession"
  return Alexa::Response.build(response_text: "Goodbye", end_session: true)
end
```

Let's upgrade our `Alexa::Response` across the board, to take named parameters. Our tests need to change first:

```ruby
# inside spec/alexa_response_spec.rb
require 'alexa/response'

RSpec.describe Alexa::Response do
  subject(:response) { described_class.build }

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

      custom_response = described_class.build(response_text: "Custom String")
      expect(custom_response).to eq expected_response
    end

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

      session_response = described_class.build(session_attributes: { sessionKey: "Session Value" })
      expect(session_response).to eq expected_response
    end

    it 'returns a JSON response that "starts over" by clearing the Session Attributes if provided' do
      expected_response = {
        version: "1.0",
        sessionAttributes: {},
        response: {
          outputSpeech: {
            type: "PlainText",
            text: "Hello World"
          }
        }
      }.to_json

      start_over_response = described_class.build(start_over: true)
      expect(start_over_response).to eq expected_response
    end

    it 'returns a JSON response with an endSessionRequest if provided' do
      expected_response = {
        version: "1.0",
        response: {
          outputSpeech: {
            type: "PlainText",
            text: "Hello World"
          },
          shouldEndSession: true
        }
      }.to_json

      end_session_response = described_class.build(end_session: true)
      expect(end_session_response).to eq expected_response
    end

    it 'returns a minimal JSON response otherwise' do
      minimal_response = { 
        version: "1.0",
        response: {
          outputSpeech: {
              type: "PlainText",
              text: "Hello World"
            }
        }
      }.to_json
      
      expect(response).to eq minimal_response
    end
  end
end
```

Now, so should our `Alexa::Response`. While we're in there, let's use Extract Method a bunch of times to pull some of the response-construction procedures out for greater clarity:

```ruby
# inside lib/alexa/response.rb
require 'json'

module Alexa
  class Response < Hash
    def initialize(response_text, session_attributes, end_session, start_over)
      @response_text      = response_text
      @session_attributes = session_attributes
      @end_session        = end_session
      @start_over         = start_over

      set_version
      set_session_attributes
      set_response
    end

    def self.build(response_text: "Hello World", session_attributes: {}, end_session: false, start_over: false)
      new(response_text, session_attributes, end_session, start_over).to_json
    end

    private

    def set_version
      self[:version] = "1.0"
    end

    def set_session_attributes
      return self[:sessionAttributes] = {} if @start_over
      self[:sessionAttributes] = @session_attributes unless @session_attributes.empty?
    end

    def set_response
      self[:response] = Hash.new
      self[:response][:outputSpeech] = Hash.new
      self[:response][:outputSpeech][:type] = "PlainText"
      self[:response][:outputSpeech][:text] = @response_text
      self[:response][:shouldEndSession] = @end_session if @end_session
    end
  end
end
```

We can now use our upgraded `Alexa::Response` to replace a bunch of painful code inside `server.rb`:

```ruby
# in server.rb
require 'sinatra'
require 'json'
require 'imdb'

post '/' do 
  parsed_request = JSON.parse(request.body.read)

  if parsed_request["request"]["intent"]["name"] == "AMAZON.StartOverIntent"
    response_text = "OK, what movie would you like to know about?"
    return Alexa::Response.build(response_text: response_text, start_over: true)
  end

  if parsed_request["request"]["intent"]["name"] == "MovieFacts"
    requested_movie = parsed_request["request"]["intent"]["slots"]["Movie"]["value"]
    movie_list = Imdb::Search.new(requested_movie).movies
    movie = movie_list.first

    response_text = movie.plot_synopsis

    return Alexa::Response.build(response_text: response_text, session_attributes: { movieTitle: requested_movie })
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

  Alexa::Response.build(response_text: response_text, session_attributes: { movieTitle: movie_title })
end
```

Now, let's try upgrading our `Alexa::Request` to refactor a bunch of the other code.

### Extending the Alexa Request to read from the Session

We cannot immediately wrap the Sinatra request inside our `Alexa::Request`, because our controller code needs to be able to access the session. We must extend our `Alexa::Request` to read the value of a session attribute:

We also need to add the ability to **read the IntentName** from an `Alexa::Request`. We'll do each of these refactors in turn.

> Another way to think of these extensions is: we need to eliminate references to `parsed_request` in `server.rb`.

#### Extension 1: What is the value of a session attribute?

Here are the offending lines which could benefit from some refactoring:

```ruby
# inside server.rb, with some omissions for brevity

parsed_request = JSON.parse(request.body.read)
...
movie_title = parsed_request["session"]["attributes"]["movieTitle"]
```

A much more pleasant design would be:

```ruby
# inside server.rb, with some omissions for brevity

alexa_request = Alexa::Request.new(request)
...
movie_title = alexa_request.session_attribute("movieTitle")
```

Let's write a test for a `#session_attribute` method that reads from the session in an `Alexa::Request` instance:

```ruby
# inside spec/alexa_request_spec.rb, with some omissions for brevity

describe '#session_attribute' do
  it 'is true if this is a new session' do
    # Let's use a relevant part of the JSON visible
    # when a request is sent via the Service Simulator
    request_json = {
      "session": {
        "sessionId": "id_string",
        "attributes": {
          "movieTitle": "Titanic"
        }
      }
    }.to_json

    sinatra_request = double("Sinatra::Request", body: StringIO.new(request_json))

    expect(Alexa::Request.new(stubbed_request).session_attribute("movieTitle")).to eq "Titanic"
  end
end
```

Again, passing this test is relatively simple:

```ruby
# inside lib/alexa/request.rb, with some omissions for brevity

def session_attribute(attribute_name)
  @request["session"]["attributes"][attribute_name]
end
```

#### Extension 2: reading the `IntentName` from an `Alexa::Request`

Here are the offending lines which could benefit from some refactoring:

```ruby
# inside server.rb, with some omissions for brevity

parsed_request = JSON.parse(request.body.read)
...
if parsed_request["request"]["intent"]["name"] == "AMAZON.StartOverIntent"
...
if parsed_request["request"]["intent"]["name"] == "MovieFacts"
...
if parsed_request["request"]["intent"]["name"] == "FollowUp"
...
```

A much more pleasant design would be:

```ruby
# inside server.rb, with some omissions for brevity

alexa_request = Alexa::Request.new(request)
...
if alexa_request.intent_name == "AMAZON.StartOverIntent"
...
if alexa_request.intent_name == "MovieFacts"
...
if alexa_request.intent_name == "FollowUp"
...
```

Let's write a test for an `#intent_name` method that reads the Intent Name on an `Alexa::Request` instance:

```ruby
# inside spec/alexa_request_spec.rb, with some omissions for brevity

describe '#intent_name' do
  it 'returns the Intent Name from the request' do
    request_json = {
      "request": {
        "type": "IntentRequest",
        "intent": {
          "name": "IntentName"
        }
      }
    }.to_json

    sinatra_request = double("Sinatra::Request", body: StringIO.new(request_json))

    expect(Alexa::Request.new(sinatra_request).intent_name).to eq "IntentName"
  end
end
```

Again, passing this test is fairly trivial:

```ruby
# inside lib/alexa/request.rb, with some omissions for brevity

def intent_name
  @request["request"]["intent"]["name"]
end
```

With that, we are ready to replace a large chunk of `server.rb`, optimising for readability!

### Refactoring `server.rb` with our new `Alexa::Request`

Let's replace some of the clunky `server.rb` code with our new `Alexa::Request` objects:

```ruby
# in server.rb
require 'sinatra'
require 'imdb'

post '/' do 
  alexa_request = Alexa::Request.new(request)

  if alexa_request.intent_name == "AMAZON.StartOverIntent"
    response_text = "OK, what movie would you like to know about?"
    Alexa::Response.build(response_text: response_text, start_over: true)
  end

  if alexa_request.intent_name == "MovieFacts"
    requested_movie = alexa_request.slot_value("Movie")
    movie_list = Imdb::Search.new(requested_movie).movies
    movie = movie_list.first

    response_text = movie.plot_synopsis

    return Alexa::Response.build(response_text: response_text, session_attributes: { movieTitle: requested_movie })
  end

  if alexa_request.intent_name == "FollowUp"
    movie_title = alexa_request.session_attribute("movieTitle")
    movie_list = Imdb::Search.new(movie_title).movies
    movie = movie_list.first

    if alexa_request.session_attribute("Role") == "directed"
      response_text = "#{movie_title} was directed by #{movie.director.join}"
    end

    if alexa_request.session_attribute("Role") == "starred in"
      response_text = "#{movie_title} starred #{movie.cast_members.join(", ")}"
    end

    return Alexa::Response.build(response_text: response_text, session_attributes: { movieTitle: movie_title })
  end
end
```

That's much neater! However, we can see a kind of 'routing' idea emerging. That is: our application rules are principally determined by the kind of Intent requested, which each evoke a specific set of logic. What can we do about that? First, let's extract a `Movie` object so we can see more clearly.

### Tidying up with a `Movie` model

Our `server.rb` is looking much tidier, but it's still quite unpleasant. Just as in our Number Facts application, we have quite a lot of logic concerning 'movies', but no central representation of the domain concept of a `Movie`.

To get towards this, let's extract subroutines that seem concerned with movies, and give them useful names:

```ruby
# in server.rb

require 'sinatra'
require 'imdb'

post '/' do 
  alexa_request = Alexa::Request.new(request)

  if alexa_request.intent_name == "AMAZON.StartOverIntent"
    # We can use Extract Method here
    return respond_with_start_over
  end

  if alexa_request.intent_name == "MovieFacts"
    # And here
    return respond_with_movie_plot_synopsis(alexa_request)
  end

  if alexa_request.intent_name == "FollowUp"
    # And here
    respond_with_movie_details(alexa_request)
  end
end

def respond_with_start_over
  response_text = "OK, what movie would you like to know about?"
  
  Alexa::Response.build(response_text: response_text, start_over: true)
end

def respond_with_movie_plot_synopsis(alexa_request)
  requested_movie = alexa_request.slot_value("Movie")
  movie_list = Imdb::Search.new(requested_movie).movies
  movie = movie_list.first

  response_text = movie.plot_synopsis

  return Alexa::Response.build(response_text: response_text, session_attributes: { movieTitle: requested_movie })
end

def respond_with_movie_details(alexa_request)
  movie_title = alexa_request.session_attribute("movieTitle")
  movie_list = Imdb::Search.new(movie_title).movies
  movie = movie_list.first

  if alexa_request.session_attribute("Role") == "directed"
    response_text = "#{movie_title} was directed by #{movie.director.join}"
  end

  if alexa_request.session_attribute("Role") == "starred in"
    response_text = "#{movie_title} starred #{movie.cast_members.join(", ")}"
  end

  Alexa::Response.build(response_text: response_text, session_attributes: { movieTitle: movie_title })
end
```

This is a pretty good start: already our `POST /` route is looking like a pretty simple representation of our rules from earlier:

- If the user asks to 'start over', clear the Session Attributes.
- If the user asks about a movie, respond with the plot synopsis for that movie, and write that movie to the session.
- If the user asks a follow-up question, read which movie they were talking about from the session and respond with more information about that movie.

Let's kick off a `Movie` object with the biggest win: pulling that messy `Imdb::Search` code into an object. Here's how it could work:

```ruby
def respond_with_movie_plot_synopsis(alexa_request)
  requested_movie = alexa_request.slot_value("Movie")
  movie = Movie.find(requested_movie)

  Alexa::Response.build(response_text: movie.plot_synopsis, session_attributes: { movieTitle: requested_movie })
end
```

Let's write a test for an interface like this:

```ruby
# in spec/movie_spec.rb
require 'movie'

RSpec.describe Movie do
  describe '.find' do
  it 'delegates finding a movie to an Imdb client search' do
      client = double("Imdb::Search")
      expect(client).to receive_message_chain(:new, :movies, :first)

      described_class.find("Some Movie Title", client)
    end
  end
end
```

The implementation for this is pretty simple:

```ruby
# in lib/movie.rb
require 'imdb'

class Movie
  def self.find(movie_title, client = Imdb::Search)
    movie_list = client.new(movie_title).movies
    movie_list.first
  end
end 
```

This moves our controller code in a much nicer direction:

```ruby
# in server.rb

require 'sinatra'
require 'imdb'

post '/' do 
  alexa_request = Alexa::Request.new(request)

  if alexa_request.intent_name == "AMAZON.StartOverIntent"
    # We can use Extract Method here
    return respond_with_start_over
  end

  if alexa_request.intent_name == "MovieFacts"
    # And here
    return respond_with_movie_plot_synopsis(alexa_request)
  end

  if alexa_request.intent_name == "FollowUp"
    # And here
    respond_with_movie_details(alexa_request)
  end
end

def respond_with_start_over
  response_text = "OK, what movie would you like to know about?"
  
  Alexa::Response.build(response_text: response_text, start_over: true)
end

def respond_with_movie_plot_synopsis(alexa_request)
  movie = Movie.find(alexa_request.slot_value("Movie"))

  return Alexa::Response.build(response_text: movie.plot_synopsis, session_attributes: { movieTitle: movie.title })
end

def respond_with_movie_details(alexa_request)
  movie = Movie.find(alexa_request.session_attribute("movieTitle"))

  if alexa_request.session_attribute("Role") == "directed"
    response_text = "#{movie_title} was directed by #{movie.director.join}"
  end

  if alexa_request.session_attribute("Role") == "starred in"
    response_text = "#{movie_title} starred #{movie.cast_members.join(", ")}"
  end

  Alexa::Response.build(response_text: response_text, session_attributes: { movieTitle: movie.title })
end
```

While this is much better, there are some convenience opportunities: namely, why construct the `response_text` variables in the `respond_with_movie_details` method inside the controller? We could hand that off to the `Movie` class. Ditto for `movie.director`, and `movie.cast_members`.

Here are some tests for these convenience methods:

```ruby
# inside spec/movie_spec.rb, with some omissions for brevity

describe '#cast_list' do
  it 'returns a human-readable string of cast members' do
    imdb_record = double("Imdb::Movie", title: "Movie", cast_members: ["Famous star 1", "Famous star 2"])

    expect(described_class.new(imdb_record).cast_members).to eq "Movie starred Famous star 1, Famous star 2"
  end
end

describe '#directors' do
  it 'returns a human-readable string of director names' do
    imdb_record = double("Imdb::Movie", title: "Movie", director: ["Famous director"])

    expect(described_class.new(imdb_record).directors).to eq "Movie was directed by Famous director"
  end
end
```

And an implementation that also includes `Forwardable` to delegate some methods through `Movie` to the underlying record retrieved via the `Imdb` gem:

```ruby
# inside lib/movie.rb

require 'imdb'
require 'forwardable'

class Movie
  extend Forwardable
  def_delegators :@imdb_record, :title, :plot_synopsis

  def initialize(imdb_record)
    @imdb_record = imdb_record
  end

  def self.find(movie_title, client = Imdb::Search)
    movie_list = client.new(movie_title).movies
    new(movie_list.first)
  end

  def cast_members
    "#{ title } starred #{ @imdb_record.cast_members.join(", ") }"
  end

  def directors
    "#{ title } was directed by #{ @imdb_record.director.join }"
  end
end
```

This allows us to achieve the following inside our methods:

```ruby
# inside server.rb

post '/' do
  ... controller code ...
end

### CONTROLLER CONVENIENCE METHODS ###

def respond_with_start_over
  response_text = "OK, what movie would you like to know about?"
  
  Alexa::Response.build(response_text: response_text, start_over: true)
end

def respond_with_movie_plot_synopsis(alexa_request)
  movie = Movie.find(alexa_request.slot_value("Movie"))
  Alexa::Response.build(response_text: movie.plot_synopsis, session_attributes: { movieTitle: movie.title })
end

def respond_with_movie_details(alexa_request)
  movie = Movie.find(alexa_request.session_attribute("movieTitle"))

  response_text = movie.directors if alexa_request.slot_value("Role") == "directed"
  response_text = movie.cast_members if alexa_request.slot_value("Role") == "starred in"

  Alexa::Response.build(response_text: response_text, session_attributes: { movieTitle: movie.title })
end
```

Much nicer!

### Extracting Handlers

Our `POST` route is looking an awful lot like a 'routing' system, that routes to certain 'convenience methods' depending on the Intent received. Each of these 'convenience methods' could be expressed as being a 'Handler'. We should be able to represent them in our framework.

Let's start by clearly delineating the 'routing' code and the 'handling' code:

```ruby
require 'sinatra'
require './lib/alexa/request'
require './lib/alexa/response'
require './lib/movie'

### 'ROUTING' CODE ###

post '/' do 
  alexa_request = Alexa::Request.new(request)

  case alexa_request.intent_name
  when "AMAZON.StartOverIntent"
    respond_with_start_over
  when "MovieFacts"
    respond_with_movie_plot_synopsis(alexa_request)
  when "FollowUp"
    respond_with_movie_details(alexa_request)
  end
end

### 'HANDLING' CODE ###

def respond_with_start_over
  response_text = "OK, what movie would you like to know about?"
  
  Alexa::Response.build(response_text: response_text, start_over: true)
end

def respond_with_movie_plot_synopsis(alexa_request)
  movie = Movie.find(alexa_request.slot_value("Movie"))
  response_text = movie.plot_synopsis

  Alexa::Response.build(response_text: response_text, session_attributes: { movieTitle: movie.title })
end

def respond_with_movie_details(alexa_request)
  movie = Movie.find(alexa_request.session_attribute("movieTitle"))

  response_text = movie.directors if alexa_request.slot_value("Role") == "directed"
  response_text = movie.cast_members if alexa_request.slot_value("Role") == "starred in"

  Alexa::Response.build(response_text: response_text, session_attributes: { movieTitle: movie.title })
end
```

:construction: This last section is under construction. Please give your thoughts on the current Handler approach in lib/alexa and in the intents directory. :construction:

## Wrapping up

In this module, we've covered a variety of techniques to extract a framework for interacting with Amazon Alexa using Ruby. This framework is available [here](http://github.com/sjmog/ralyxa) to play with and extend, if you wish.