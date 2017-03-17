# Alexa 3: Conversational Movie Facts

Now that we’re comfortable with the Alexa communication paradigm, using Intents and Utterances, and Slots (and Custom Slots), let’s introduce another major component of the Alexa Skills Kit: Sessions.

We’re going to build an application that allows users to ask this:

> Alexa, ask Movie Facts about Titanic.

Alexa should respond with some facts about the film ‘Titanic’. Then, our users should be able to ask context-based questions, such as:

> Alexa, ask Movie Facts who directed that.
> Alexa, ask Movie Facts who starred in that.

Alexa should respond with the director of ‘Titanic’, and a cast list. 

Alexa should remember that the user asked about ‘Titanic’ in the first request, and limit her response to subsequent requests to the context of the first.

## 1. An introduction to Sessions

To build this Conversational Interface, we will need to make use of Alexa’s ability to manage Sessions.

> A ‘Conversational Interface’ allows users to engage in dialogue with technology, with the technology providing meaningful responses based on the context of the dialogue.

Set up a new skill, with an Invocation Name of ‘Movie Facts’, and a new Sinatra application. Again, we’ll be using ngrok to tunnel our development server over HTTPS, and providing the ngrok HTTPS endpoint to our skill as our endpoint.

> Feel free to use another method of connecting a Ruby application to Alexa via HTTPS. We’ll move forward assuming you’re using an ngrok Tunnel, but you can adapt as desired.

Before we try and build our Movie Facts skill, let’s get to grips with some key concepts regarding Sessions: what they are, how we use them, and why they’re handy. We’ll build a simple VUI that responds to the following:

> Alexa, ask Movie Facts to talk to me.

Alexa should respond with “This is the first question”, **but only on the first request**. On all subsequent requests, Alexa should respond with a count of how many questions the user has asked.

In other words, when a user asks:

> Alexa, ask Movie Facts to talk to me.

Alexa should respond with “this is question number number”, depending on how many times the user has asked Movie Facts to talk with them.

Let’s set up a minimal Intent Schema, using the Intent name `MovieFacts`:

```json
{
 "intents": [
    "intent": "MovieFacts"
  ]
}
```

We’ll add a simple Utterance:

```
MovieFacts talk to me
```

Now, in our Sinatra application, we can provide a simple minimal response. In addition, let’s print the request so we can have a look at it:

```ruby
require 'sinatra'
require 'json'

post '/' do 
  parsed_request = JSON.parse(request.body.read)
  
  # Send back a simple response
  return { 
      version: "1.0",
      response: {
        outputSpeech: {
            type: "PlainText",
            text: "This is the first question"
          }
      }
    }.to_json
end
```

When we run this in the service simulator, take a look at the `"session"` key:

```json
"session"=>{
 "new"=>true, 
  "sessionId"=>"SessionId.120a73d8-c1dc-437c-8c5b-fb2d1057f991",
  "application"=>{"applicationId"=>"A long string"}, 
  "attributes"=>{}, 
  "user"=>{"userId"=>"A long string"}
}
```

Notice that the session key tells us that this is a **new** session. Now let’s pass the same Utterance to the Service Simulator again. Notice how the `"session"` key changes with this second request:

```json
"session"=>{
 "new"=>false, 
  "sessionId"=>"SessionId.120a73d8-c1dc-437c-8c5b-fb2d1057f991",
  "application"=>{"applicationId"=>"A long string"}, 
  "attributes"=>{}, 
  "user"=>{"userId"=>"A long string"}
}
```json

Alexa will remember that this user has already asked Movie Facts a question, and mention that in the request: the session `"new"` value has changed from `true` to `false`.

Now that we know this, let’s upgrade our application to respond with two different strings, depending on whether this is the first question the user has asked:

```ruby
require 'sinatra'
require 'json'

post '/' do 
  parsed_request = JSON.parse(request.body.read)
  this_the_first_question = parsed_request["session"]["new"]

  if this_is_the_first_question
    return { 
      version: "1.0",
      response: {
        outputSpeech: {
            type: "PlainText",
            text: "This is the first question."
          }
      }
    }.to_json
  end

  return {
    version: "1.0",
    response: {
      outputSpeech: {
          type: "PlainText",
          text: "This is question number 2"
        }
    }
  }.to_json
end
```

Running in the Service Simulator, or on any Alexa-enabled device, we receive the first message first, and the second message for all subsequent requests.

> If you’re using the Service Simulator, don’t forget to refresh the page to start a new session with Alexa.

However, there’s a problem: at the moment, the user will first hear “This is the first question”, and then they’ll hear “This is question number 2” _forever_ – regardless of how many times they ask. We need a way to **persist information** about how many questions the user has asked, and reference it between requests.

To persist information between requests in this way, we can use **Session Attributes**. Sessions can store information about what a user has said to Alexa in the past, and our Sinatra application can use that persisted information to construct a response.

First, we need to initialise the Session Attributes for our first response to include a new attribute, `numberOfRequests`:

```ruby
# for brevity, here's just the Ruby code making the first response
if this_is_the_first_question
     return { 
       version: "1.0",
        # here, we can persist data across multiple requests and responses
       sessionAttributes: {
        numberOfRequests: 1
      },
       response: {
         outputSpeech: {
             type: "PlainText",
             text: "This is the first question."
          }
      }
 }.to_json
end
```

Using `puts` to output the request body, notice how the request now contains a reference to the number of requests made, in an attribute called `numberOfRequests`:

```json
"session"=>{
  "new"=>true, 
  "sessionId"=>"a long string", 
  "application"=>{"applicationId"=>"a long string"}, 
  "attributes"=>{"numberOfRequests"=>1}
```

Now that the user has initialised the number of requests in their first interaction with Alexa, we can increment it in each subsequent interaction:

```ruby
# for brevity, here's just the Ruby code for subsequent responses
number_of_requests = parsed_request["session"]["attributes"]["numberOfRequests"] + 1

  return {
    version: "1.0",
    sessionAttributes: {
      numberOfRequests: number_of_requests
    },
    response: {
      outputSpeech: {
        type: "PlainText",
        text: "This is question number #{ number_of_requests }"
      }
    }
  }.to_json
```

Now, we are persisting – and acting on – data across multiple interactions. Try it out in the Service Simulator!

One final thing – what about if we want to allow users to go back to the beginning? To do that, we’d need to clear the Session.

Let’s allow users to say:

> Alexa, ask Movie Facts to start over.

We need to add an Utterance for this:

```
ClearSession start over
```

And a new Intent, with an Intent name of `ClearSession`:

```json
  {
    "intents": [
      {
        "intent": "ClearSession"
      },
    ... rest of the Intent Schema
```

In our Sinatra application, let’s add a response just for requests to clear the Session. To clear a Session, we should add `shouldEndSession: true` to the response:

```ruby
if parsed_request["request"]["intent"]["name"] == "ClearSession"
  return {
    version: "1.0",
    response: {
      outputSpeech: {
        type: "PlainText",
        text: "Let's start over."
      },
    # adding this line to a response will clear the Session
    shouldEndSession: true
  }
}.to_json
```

> Once a Session is reset, any Session Attributes are removed.

Now a user can reset their session, and start the question count over! Now let’s use our skills to do something a little more complex.

> Users can end a session any time in one of three circumstances:
> 1. The user says “exit”,
> 2. The user does not respond, or says something that does not match an intent you have defined
> 3. An error occurs.
> In either of these cases, your Sinatra Application will receive a special type of request: a `SessionEndedRequest`. Your application cannot return a response to `SessionEndedRequest`s.

## 2. Querying IMDb

First, we want users to be able to ask:

> Alexa, ask Movie Facts about some movie name.

Let’s upgrade our first Utterance to respond to information about movies:
```
MovieFacts about {Movie}
```

If your skill is an English (US) skill, you can use Amazon’s built-in `AMAZON.Movie` Slot Type to pass the name of the film. If not, you’ll need to define a Custom Slot Type with the names of several films, to guide voice recognition for whichever film the user requests. Assuming the latter, let’s define a Custom Slot Type, named `MOVIE`, with a definition containing a few example films:

```
titanic
jaws
the perfect storm
```

(If you would prefer to use an exhaustive list of movies available on the Internet Movie Database (IMDb), you can find a list of every movie IMDb has listed [here](ftp://ftp.funet.fi/pub/mirrors/ftp.imdb.com/pub/).)

Add a slot with the appropriate slot type to your Intent Schema, and test that your slot is filled appropriately by printing requests to your Sinatra application.

In our Sinatra application, let’s use the Open-Source [IMDb gem](https://github.com/ariejan/imdb) to query IMDb for information about whichever movie the user wants to know more about:

```ruby
require 'sinatra'
require 'json'
# include the IMDb gem to query IMDb easily
require 'imdb'

post '/' do 
  parsed_request = JSON.parse(request.body.read)
  this_is_the_first_request = parsed_request["session"]["new"]

  if this_is_the_first_request
    # Fetch the name of the movie the user wanted information about
    requested_movie = parsed_request["request"]["intent"]["slots"]["Film"]["value"]
    # Search IMDb for all movies matching that name
    movie_list = Imdb::Search.new(requested_movie).movies
    # Pick the first one
    movie = movie_list.first

    return { 
      version: "1.0",
      response: {
        outputSpeech: {
            type: "PlainText",
            # Return the plot synopsis for that movie to the user
            text: movie.plot_synopsis
          }
      }
    }.to_json
  end
end
```

> Remember to run the command-line command `gem install imdb` before you try to run your Sinatra application (or use a more rigorous dependency management system such as [Bundler](http://bundler.io/gemfile.html)).

Once you’ve verified this is all working in the Service Simulator, let’s move on to the final section: using the session to make a Conversational Interface.

## 3. Building a dialogue

So far, our users can ask Alexa:

> Alexa, ask Movie Facts about some movie name.

Alexa will respond with the plot synopsis for the first movie matching the name the user provides. For example, if a user asks “Alexa, ask Movie Facts about Titanic”, Alexa will respond with a plot synopsis for the 1997 movie _Titanic_.

We’d love our users to ask follow-up questions about the movie they initially queried – but how can we do that without requiring the user give the movie name a second time? Let’s use Session Attributes!

We can persist the title of the requested movie after our initial request:

```ruby
if this_is_the_first_request
  requested_movie = parsed_request["request"]["intent"]["slots"]["Film"]["value"]
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
```

Now we can access the movie title on subsequent requests. We want our users to be able to query for information about the movie, such as:

> Alexa, ask Movie Facts who directed that.
> Alexa, ask Movie Facts who starred in that.

Let’s create an Utterance for this:

```
MovieFacts who {Role} that
```

And a Custom Slot Type for possible Roles people might have in the movie, called `ROLE`:

```
directed
starred in
```

Now let’s add that Custom Slot to our Intent Schema:

```json
"intents": [
  {
    "intent": "MovieFacts",
    "slots": [
      {
        "name": "Movie",
        "type": "MOVIE"
      },
      {
        "name": "Role",
        "type": "ROLE"
      }
    ]
  }
]
```

Now, we need to ensure our Sinatra application can respond to these subsequent requests:

```ruby
# After the block that handles the first request
# Fetch the movie title from the Session Attributes
movie_title = session["attributes"]["movieTitle"]
# Search again for this movie, and pull out the first one
  movie_list = Imdb::Search.new(movie_title).movies
  movie = movie_list.first

# Find out which Role the user was interested in
# this could be 'directed' or 'starred in' (or any other Values
# we provided to our Custom Slot Type)
  role = parsed_request["request"]["intent"]["slots"]["Role"]["value"]

# Construct response text if the user wanted to know
# who directed the movie
  if role == "directed"
    response_text = "#{movie_title} was directed by #{movie.director.join}"
  end

# Construct response text if the user wanted to know
# who starred in the movie
  if role == "starred in"
    response_text = "#{movie_title} starred #{movie.cast_members.join(", ")}"
  end

# Pass the response text to the response, and remember to
# store the movie title in the Session Attributes so users
# can make subsequent requests about role in this movie
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
```

Let’s test this out in the Service Simulator, or on any Alexa-enabled device. First, the user can ask:

> Alexa, ask Film Facts about Titanic.

Alexa responds with “In 1996, treasure hunter Brock Lovett…”: the plot synopsis for Titanic. But who directed it?

> Alexa, ask Film Facts who directed that.

Alexa responds with "Titanic was directed by James Cameron”. Great! And, because we’re storing the movie title in the Session Attributes, our users can continue querying:

> Alexa, ask Film Facts who starred in that.

Alexa responds with a list of cast members for the 1997 film _Titanic_. And, because we’ve added a Session-clearing intent, users can ask:

> Alexa, start over.

And they’ll be offered the chance to start querying a new movie. Awesome!

> EXTRA CREDIT 1: It’s can take a while to search IMDb and then whittle down the response to a single movie. Using a more sophisticated set of Session Attributes, try persisting information relevant to the film in the session, and extracting subsequent user requests from the session instead of querying IMDb.

> EXTRA CREDIT 2: Our codebase is looking pretty scrappy, and it’s highly procedural. There are a few things that feel like they’re violating the ‘Don’t Repeat Yourself’ rule by duplicating knowledge about the system at several points. Try refactoring the procedural codebase into something a little more OO. If you do it right, you’ll wind up with the start of a useful framework that could abstract some of the messy JSON manipulation we’ve been doing.

> EXTRA CREDIT 3: It’s important to know that the request to your application is coming from Alexa, and not from anywhere else (say, a user trying to access your application via cURL from the command-line).
> To do this, Amazon recommend that before taking any action on a request, developers first **verify** the request you receive comes from the application you expect.
> JSON requests from the Amazon Alexa Service come with a key for doing just this: the `session.application.applicationId`. The value for this key is a string. For extra credit, add a guard clause to verify that the request came from your application, and return an appropriate HTTP error if it does not.