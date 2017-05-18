# Alexa 5: Persisting and Retrieving Data

> We will be using the [Ralyxa](https://github.com/sjmog/ralyxa) framework during this module.

We have constructed a series of skills that allow us to interact with, and control, Alexa. However, our skills rely on data held in-memory within our Sinatra applications. All data passed to and from Alexa is wiped whenever we restart our Sinatra application.

During this module, you will construct an intermediate skill called _Pizza Buddy_. This skill will allow users to:

- Place pizza orders, and
- Query orders that have been made.

We will use the Session to design a multi-stage ordering process. We will store and retrieve orders using a [Postgres](https://www.postgresql.org/) relational database. We will use [Datamapper](http://datamapper.org/) as the translation later ('ORM') between our Sinatra application and the Postgres database. Finally, we will post Cards to the user, displaying simple information about the orders that have been made.

## Overview

> A completed version of the _Pizza Buddy_ application is available [here](https://github.com/sjmog/pizza_buddy). You can use the commits to guide your build, or fork and play with the completed application. This walkthrough covers commits 1 - 12.

Here are the following steps to take. You might wish to try building _Pizza Buddy_ using these steps alone, before returning to this walkthrough should you need more support. The walkthrough continues after these steps.

### Setting up a new skill and application using Ralyxa
1. Set up a new skill, called 'Pizza Buddy', with an invocation name of 'pizza buddy'
2. Set up a new Sinatra application, tunneled with ngrok
3. Install the latest version of [Ralyxa](https://github.com/sjmog/ralyxa) to the application ([Checkpoint 1](https://github.com/sjmog/pizza_buddy/commit/b151b1e90e3d01aabf889721a45bf5e8db2fd0ea))

### Defining a multi-stage conversation
4. Define a `StartPizzaOrder` intent in the Alexa Developer Portal, with no slots. The `StartPizzaOrder` intent should have a single Utterance: "StartPizzaOrder new pizza". 
5. Define a `StartPizzaOrder` intent declaration in the Sinatra application, responding with a prompt to pick a size of pizza.
6. Define a `LaunchRequest` intent declaration in the Sinatra application. Respond with a simple 'welcome' message ([Checkpoint 2](https://github.com/sjmog/pizza_buddy/commit/caac02c0c11234dc877141c45df3311c2604a53f))
7. Add a `Pizza` object to the Sinatra application, which presents the available sizes of pizza ([Checkpoint 3](https://github.com/sjmog/pizza_buddy/commit/4e554f02e72c9493c4c77e3100826aafeedb12f4))
8. Define a `ContinuePizzaOrder` intent in the Alexa Developer Portal, with one slot, named `size`, of type `PIZZA_SIZE`, a custom slot. Define a custom slot, `PIZZA_SIZE`, with values depending on the sizes you offer in your response to the `StartPizzaOrder` intent.
9. Define a `ContinuePizzaOrder` intent declaration which saves the user's choice of pizza size to the session, and prompts for pizza toppings
10. Define a `PenultimatePizzaOrder` intent in the Alexa Developer Portal, with five slots: `toppingOne` to `toppingFive`. Each slot should have a type of `PIZZA_TOPPING`, a custom slot. Define a custom slot, `PIZZA_TOPPING`, with values depending on the toppings you want to offer.
11. Define the Utterances for the `PenultimatePizzaOrder` intent with cascading slot values:

```
PenultimatePizzaOrder {toppingOne}
PenultimatePizzaOrder {toppingOne} {toppingTwo}
PenultimatePizzaOrder {toppingOne} {toppingTwo} {toppingThree}
PenultimatePizzaOrder {toppingOne} {toppingTwo} {toppingThree} {toppingFour}
PenultimatePizzaOrder {toppingOne} {toppingTwo} {toppingThree} {toppingFour} {toppingFive}
```

12. Define a `PenultimatePizzaOrder` intent declaration in the Sinatra application, which confirms the size and toppings (and saves them to the session) ([Checkpoint 4](https://github.com/sjmog/pizza_buddy/commit/0fc940187405ed9eb29e8a05929e4a7308cdc831))
13. Check that the user has not provided any disallowed toppings, and update the response to `PenultimatePizzaOrder` to reprompt users for more appropriate choices if they get it wrong ([Checkpoint 5](https://github.com/sjmog/pizza_buddy/commit/7bfe879d5e4b3bdf98d4937d90fce19fc27ab9fa))
14. Define a `ConfirmPizzaOrder` intent in the Alexa Developer Portal, with an Utterance "ConfirmPizzaOrder confirm my order"
15. Define a `ConfirmPizzaOrder` intent declaration in the Sinatra application, which uses Datamapper and Postgres to save the confirmed pizza to the database ([Checkpoint 6](https://github.com/sjmog/pizza_buddy/commit/584832e8ce4dfe396b39d2831897f7224967e153))

### Interacting with persisted data
16. Implement a `ListOrders` intent in both the Alexa Developer Portal and the Sinatra application, which gives information about `Pizza` entities saved in the database ([Checkpoint 7](https://github.com/sjmog/pizza_buddy/commit/4c125ed0ed0f39f7e6d927b4e337eccbd9977f38))
17. Implement a `ListToppings` intent in both the Alexa Developer Portal and the Sinatra application, which lists the available permitted toppings users can add to a pizza ([Checkpoint 8](https://github.com/sjmog/pizza_buddy/commit/54dd44349c5a0fef17fdd0df7708ef644b21bd86))
18. Add a [Standard Card](https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/providing-home-cards-for-the-amazon-alexa-app#creating-a-home-card-to-display-text-and-an-image) in response to a `ConfirmPizzaOrder` intent, using Ralyxa's [Card API](https://github.com/sjmog/ralyxa#using-cards) ([Checkpoint 9](https://github.com/sjmog/pizza_buddy/commit/0ddf8aeaa8adf9578782f0fa824a5ca8b45e8037))

Let's walk through step-by-step!

## Setting up a new skill and application using Ralyxa

##### 1. Set up a new skill, called 'Pizza Buddy', with an invocation name of 'pizza buddy'

Our first step, as always, is to set up the skill on Amazon. We'll want to call this skill 'Pizza Buddy', with an invocation name of 'pizza buddy'. We won't need account linking.

##### 2. Set up a new Sinatra application, tunneled with ngrok

Create a new directory (we'll refer to this as the 'application directory'). Inside this directory, create a Gemfile, containing a single gem: `sinatra`. Also, install [ngrok](https://ngrok.com/). I'll assume you've downloaded ngrok to this directory.

Use `bundle install` to install all dependencies (in this case, just Sinatra), and add a `server.rb` file to the application directory.

> I'd advise using Ruby 2.3.1. If `bundle install` fails for you, you may need to install Bundler. Do this with `gem install bundler`.

Inside the `server.rb` file, add the following lines to a) require Sinatra, and b) add a single `POST` index route. This is the route Alexa will use to contact your application:

```ruby
# inside server.rb
require 'sinatra'

post '/' do
  # We'll fill this out in a minute
end
```

Here's your application directory at the end of this step:

```
.
├── Gemfile
├── Gemfile.lock
├── ngrok
└── server.rb
```

##### 3. Install the latest version of [Ralyxa](https://github.com/sjmog/ralyxa) to the application

You can jump directly to the end of this step by forking from [this commit](https://github.com/sjmog/pizza_buddy/commit/b151b1e90e3d01aabf889721a45bf5e8db2fd0ea).

> Ralyxa is a Ruby framework for interacting with Alexa. It simplifies a lot of the interactions on the Ruby side. This walkthrough assumes you are using, at a minimum, version 1.2.0 of Ralyxa. If you don't know your Ralyxa version, you're probably fine.

Add the `ralyxa` gem to your Gemfile, and `bundle install`. Update the `POST /` route in `server.rb` with the following:

```ruby
# inside server.rb
require 'server.rb'

post '/' do
  Ralyxa::Skill.handle(request)
end
```

> This will allow Ralyxa to hook in to, and respond to, any requests that come to your application.

Add a subdirectory within your application directory, called `intents`. This is where you will define your **Intent Declarations**, which are where you tell Ralyxa how to handle Alexa requests.

Here's your application directory at the end of this step:

```
.
├── Gemfile
├── Gemfile.lock
├── intents
├── ngrok
└── server.rb
```

> If you start the application now, with `ruby server.rb`, you'll see a warning that you haven't defined any intent declarations. This is expected, as we haven't defined any intent declarations yet.

##### 4. Define a `StartPizzaOrder` intent in the Alexa Developer Portal, with no slots. The `StartPizzaOrder` intent should have a single Utterance: "StartPizzaOrder new pizza".

In the next few steps, we hit the main bulk of our workflow. The pattern goes like this:

1. Define an Intent in our Intent Schema, in the Alexa Developer Portal. Define Utterances for this Intent (and possibly Custom Slot Types).
2. Define an **Intent Declaration** in our Sinatra application.
3. Test the two work together.

The first custom Intent will be the `StartPizzaOrder` Intent. Alexa will listen for the user to say:

> Order a pizza

And respond with:

> Great! What pizza would you like? You can pick from large, medium, and small.

First, define the Intent in the Intent Schema, in the Alexa Developer Portal:

```json
{
  "intents": [
    {
      "intent": "StartPizzaOrder"
    }
  ]
}
```

Next, define the Utterance for this intent:

```
StartPizzaOrder order a pizza
```

##### 5. Define a `StartPizzaOrder` intent declaration in the Sinatra application, responding with a prompt to pick a size of pizza.

Second, define the **Intent Declaration** in the Sinatra application. Add a new file, `start_pizza_order.rb`, to the intents subdirectory inside your application directory. Inside this, write the intent declaration as follows:

```ruby
intent "StartPizzaOrder" do
  ask("Great! What pizza would you like? You can pick from large, medium, and small.")
end
```

> It doesn't actually matter what you call this Ruby file, so long as you keep the file extension as `.rb`.

Here's how this works:

- `intent` says to Ralyxa "handle anything you hear from Alexa with an intent name `StartPizzaOrder`"
- `ask` says to Ralyxa "construct a JSON response for Alexa that makes Alexa say 'Great! What pizza would you like...'"
- Sinatra then sends this JSON back to Alexa, and Alexa asks the given question.

Test that your Alexa skill can send a `StartPizzaOrder` intent to your Sinatra application by doing the following:

- Start the development server with `ruby server.rb`.
- Start ngrok with `ngrok http 4567`, and copy the HTTPS endpoint ending in `.ngrok.io` to the clipboard.
- Add this HTTPS endpoint to your Alexa skill in the Alexa Developer Portal. If you're asked for a certificate, select "My development endpoint is a sub-domain of a domain that has a wildcard certificate from a certificate authority".
- **EITHER** use an Alexa device (or [Echosim](https://echosim.io)) to test the `LaunchRequest` by saying "Alexa, launch Pizza Buddy"
- **OR** write the following into the Service Simulator: "order a pizza", and hit 'Ask Pizza Buddy'.

If everything is correctly configured, you'll hear or see a response from your application.

Here's your application directory at the end of this step:

```
.
├── Gemfile
├── Gemfile.lock
├── intents
│   └── start_pizza_order.rb
├── ngrok
└── server.rb
```

##### 6. Define a `LaunchRequest` intent declaration in the Sinatra application. Respond with a simple 'welcome' message.

You can jump directly to the end of this step by forking from [this commit](https://github.com/sjmog/pizza_buddy/commit/caac02c0c11234dc877141c45df3311c2604a53f).

Sometimes, a user will want to launch a skill without specifying any particular action to take. This is called a `LaunchRequest`. For example:

> Alexa, launch Pizza Buddy

Should cause Alexa to respond with:

> Welcome to Pizza Buddy. Would you like a new pizza, or to list orders?

A `LaunchRequest` is a built-in Intent, so we don't need to define it in our Intent Schema. We can jump straight to implementing an **intent declaration**.

Add a new file, `launch_request.rb`, to the intents subdirectory inside your application directory. Inside this, write an intent declaration as follows:

```ruby
intent "LaunchRequest" do
  ask("Welcome to Pizza Buddy. Would you like a new pizza, or to list orders?")
end
```

Test that your Alexa skill can send a `LaunchRequest` to your Sinatra application by doing the following:

- Restart the server.
- **EITHER** use an Alexa device (or [Echosim](https://echosim.io)) to test the `LaunchRequest` by saying "Alexa, launch Pizza Buddy"
- **OR** paste the following JSON into the Service Simulator's 'JSON' panel:

```json
{
  "session": {
    "sessionId": "REDACTED",
    "application": {
      "applicationId": "REDACTED"
    },
    "attributes": {},
    "user": {
      "userId": "REDACTED"
    },
    "new": true
  },
  "request": {
    "type": "LaunchRequest",
    "requestId": "REDACTED",
    "locale": "en-GB",
    "timestamp": "2017-05-09T15:39:26Z"
  },
  "version": "1.0"
}
```

> You don't have to replace the words `REDACTED` with anything for this to send a successful `LaunchRequest`.

Here's your application directory at the end of this step:

```
.
├── Gemfile
├── Gemfile.lock
├── intents
│   ├── launch_request.rb
│   └── start_pizza_order.rb
├── ngrok
└── server.rb
```

##### 7. Add a `Pizza` object to the Sinatra application, which presents the available sizes of pizza

You can jump directly to the end of this step by forking from [this commit](https://github.com/sjmog/pizza_buddy/commit/4e554f02e72c9493c4c77e3100826aafeedb12f4).

Our `StartPizzaOrder` intent declaration currently reads as follows:

```ruby
intent "StartPizzaOrder" do
  ask("Great! What pizza would you like? You can pick from large, medium, and small.")
end
```

It would be great if this intent declaration read like this:

```ruby
intent "StartPizzaOrder" do
  ask("Great! What pizza would you like? You can pick from #{ Pizza::SIZES.to_sentence }")
end
```

Let's extract a `Pizza` object to hold the available sizes of pizza we offer. We'll follow a [Test-Driven Development](https://martinfowler.com/bliki/TestDrivenDevelopment.html) methodology. First, install [RSpec](http://rspec.info/) to the project by adding the `rspec` gem to your Gemfile, and using `bundle install` to install the dependency. Then, initialise RSpec using `rspec --init` from the command line.

> `rspec --init` should generate a couple of files for you, and a spec subdirectory. This is where our test files go.

Write a test for the `Pizza` object in a spec file, `pizza_spec.rb`, inside the spec subdirectory of your application directory:

```ruby
# in spec/pizza_spec.rb
require 'pizza'

RSpec.describe Pizza do
  describe 'SIZES' do
    it 'holds the available pizza sizes' do
      expect(described_class::SIZES).to eq [:large, :medium, :small]
    end
  end
end
```

Run the test using `rspec spec` from the application directory. It will fail: you need to create a lib directory, containing a `pizza.rb` file. This file will contain your `Pizza` code:

```ruby
# in lib/pizza.rb

class Pizza
  SIZES = [:large, :medium, :small]
end
```

Run the test again using `rspec spec` from the application directory. It should pass. We can now use our `Pizza` object in our intent declaration.

Before we can use it as intended, however, you will need to add the `activesupport` gem to your Gemfile and `bundle install` again. Now, we can express our available Pizza sizes as a string:

```ruby
require './lib/pizza'
require 'active_support/core_ext/array/conversions'

intent "StartPizzaOrder" do
  ask("Great! What pizza would you like? You can pick from #{ Pizza::SIZES.to_sentence }")
end
```

We can change our Pizza sizes easily, by altering the `Pizza::SIZES` constant and restarting the server.

Here's your application directory at the end of this step:

```
.
├── Gemfile
├── Gemfile.lock
├── intents
│   ├── launch_request.rb
│   └── start_pizza_order.rb
├── lib
│   └── pizza.rb
├── spec
│   ├── pizza_spec.rb
│   └── spec_helper.rb
├── ngrok
└── server.rb
```