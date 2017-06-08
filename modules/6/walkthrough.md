# Alexa 6: Authenticating Skill Users with OAuth

> We will be using the [Ralyxa](https://github.com/sjmog/ralyxa) framework during this module.

We have constructed an intermediate skill called _Pizza Buddy_. This skill allows users to:

- Place pizza orders, and
- Query orders that have been made.

In this module, we will authenticate users via [Open Authentication (OAuth)](https://aaronparecki.com/oauth-2-simplified/), using [Login with Amazon](http://login.amazon.com/). Users will not be able to order a pizza until they are logged into their account, and users will only be able to list pizzas that they, themselves, have ordered.

This kind of authentication is designed to work seamlessly with other user management protocols you might use in your application. We will be creating a `User` entity from scratch, but authentication in this way can hook into [Devise](https://github.com/plataformatec/devise), [Clearance](https://github.com/thoughtbot/clearance), [Sorcery](https://github.com/NoamB/sorcery), or any other authentication framework you might use.

## Overview

> A completed version of the _Pizza Buddy_ application is available [here](https://github.com/sjmog/pizza_buddy). You can use the commits to guide your build, or fork and play with the completed application. This walkthrough covers commits 16 - 20.

> You can fork directly from [this commit](https://github.com/sjmog/pizza_buddy/commit/ac5a67287562710c75e19d3f2e28f89b860aab57) to start this module.

You can take two routes through this walkthrough:

1. **Quick Steps:** have some experience of Alexa, Ruby, and OAuth? This is a challenge-based way to approach building Pizza Buddy. It's designed for people who want to build their ability to implement, rather than understand. It's a more frustrating, but rewarding, approach.
2. **Detailed Walkthrough:** new to Alexa, Ruby, or OAuth? Want to get a clear grounding in some Alexa/Ruby techniques, and understand more about OAuth? This step-by-step walkthrough guides you through the entire process. It's also a helpful reference tool for those attempting the **Quick Steps**: if you get stuck, you can refer to the detailed walkthrough.

The Quick Steps map directly onto the Detailed Walkthrough: each Quick Step has an associated chapter in the Detailed Walkthrough.

## Quick Steps

### Authenticating with OAuth

1. Set up a Login with Amazon (LWA) Security Profile, and enable your skill for Account Linking with the LWA details.
2. Send an Account Linking Card to the user if they lack an OAuth access token on launch
3. If the user has an access token during a `LaunchRequest`, authenticate and log in, or sign up, the user. [Checkpoint 1](https://github.com/sjmog/pizza_buddy/commit/3ab1c24bfddbbcc9885882dcd7a54d0e2ab7a41f)

### Managing Pizza ordering per-user

4. Modify the `ConfirmPizzaOrder` intent handler to send an Account Linking Card to the user if they lack an OAuth access token.
5. Modify pizza saving in the `ConfirmPizzaOrder` intent handler to ensure that the saved pizza `belongs_to` the authenticated user.
6. Modify the `ListOrders` intent handler to list only pizzas belonging to the currently-authenticated user.

## Detailed Walkthrough

### Authenticating with OAuth

#### 1. Set up a Login with Amazon Security Profile, and enable Account Linking in your skill

Before we can authenticate our users, we must enable Account Linking on our skill. Enabling Account Linking requires several pieces of information. To get these piece of information, we must set up a **Login with Amazon (LWA) Security Profile**.

> If you would prefer to use another OAuth service to authenticate your users, substitute the LWA setup steps with those of setting up your alternative provider.

To create a new LWA profile for your Alexa skill, log in to the [Amazon Developer Console](https://developer.amazon.com). Then:

1. click on 'Apps & Services', then
2. click 'Login with Amazon', then
3. click the button 'Create a New Security Profile'.

![](https://m.media-amazon.com/images/G/01/DeveloperBlogs/AmazonDeveloperBlogs/legacy/LWA_ZC2._CB520201684_.jpg)

Create a new security profile. Give it an appropriate name (perhaps `alexa-pizza-buddy`) and description (Pizza Buddy). For now, we'll use Amazon's Data Privacy policy: https://www.amazon.com/gp/help/customer/display.html?nodeId=468496. You should use your own for your own skills.

![](http://assets.makersacademy.com/images/alexa-ruby-course/6/security_profile.png)

> Why not use a [pizza image](http://assets.makersacademy.com/images/alexa-ruby-course/6/pizza.jpg) as the icon?

Make a note of your **Client ID** and **Client Secret**:

![](https://m.media-amazon.com/images/G/01/DeveloperBlogs/AmazonDeveloperBlogs/legacy/LWA_ZC4._CB520201646_.jpg)

Return to the Account Linking section of our _Pizza Buddy_ skill, and use the table below to fill out the required sections of the form.

| Key  | Value  |
|---|---|
| Account Linking  | Yes  |
| Authorization URL  |  https://www.amazon.com/ap/oa |
| Client ID  | The Client ID from the LWA Security Profile.  This has a format such as amzn1-application-oa2-client-xxx  |
| Scope  | LWA supports [several scopes](https://developer.amazon.com/public/apis/engage/login-with-amazon/docs/customer_profile.html). For this example, let’s use “profile”.  This will allow Pizza Buddy to retrieve a full name for the user, and greet them personally |
| Redirect URL | The Redirect URL from the 'Web Services' section of the LWA Security Profile. It may start https://layla.amazon.com |
| Authorization Grant Type  | Select 'Auth Code Grant'  |
| Access Token URI  | https://api.amazon.com/auth/o2/token  |
| Client Secret  | The Client Secret from the LWA Security Profile  |
| Client Authentication Scheme | HTTP Basic (Recommended) |

Once you save this data, you are ready to send users an Account Linking Card in the event they are not yet authenticated with your skill.

#### 2. Send an Account Linking Card to the user if they lack an OAuth access token on launch

Now that we have configured Account Linking, let's update our `LaunchRequest` intent handler to send the user an Account Linking Card if they lack an Access Token. The user's workflow will be:

1. **User:** "Alexa, launch Pizza Buddy".
2. **Alexa:** "Please authenticate Pizza Buddy via the Alexa app." Sends an Account Linking Card to the user's Alexa app.
3. **User:** launches the Alexa app, clicks the Account Linking Card, completes Login with Amazon using their Amazon customer details. Receives an Access Token in return.
4. **User:** "Alexa, launch Pizza Buddy".
5. **Alexa:** "Welcome to Pizza Buddy. Would you like a new pizza, or to list orders?"

In the first instance (1), our Sinatra application receives a JSON packet with no user access token:

```json
// redacted for brevity
{
  "session": {
    "user": {
      "userId": "<REDACTED>"
    }
  }
}
```

Once the user has completed the Login with Amazon authentication step, their subsequent requests (4) include an Access Token:

```json
// redacted for brevity
{
  "session": {
    "user": {
      "userId": "<REDACTED>",
      "accessToken": "Atza|<SOME LONG STRING>"
    }
  }
}
```

We can use the existence of this Access Token to tell if the user has authenticated with LWA yet. Ralyxa provides us with some convenience methods for reading it, and for sending the Account Linking Card if the user has not yet authenticated:

```ruby
# inside intents/launch_request.rb

intent "LaunchRequest" do
  return tell("Please authenticate Pizza Buddy via the Alexa app.", card: link_account_card) unless request.user_access_token_exists?
  
  ask("Welcome to Pizza Buddy. Would you like a new pizza, or to list orders?")
end
```

> You may need to update to the latest version of Ralyxa for the above syntax (a [guard clause](https://refactoring.com/catalog/replaceNestedConditionalWithGuardClauses.html)) to work correctly.

Using an Alexa device, test this card. On launch, the user should receive a card in their Alexa app. Clicking on that will take them to Login with Amazon. After providing their details, the user explicitly authorises Pizza Buddy to access their name and email address:

![](http://assets.makersacademy.com/images/alexa-ruby-course/6/consent.png)

Once they agree, they are redirected to a page that reports success:

![](http://assets.makersacademy.com/images/alexa-ruby-course/6/success.png)

#### 3. If the user has an access token during a `LaunchRequest`, authenticate and log in, or sign up, the user

Wouldn't it be great to welcome the user more personally to Pizza Buddy? Once the user has logged in with OAuth, we can access permitted Amazon customer data from the Amazon API. While we're doing this, we will create, or find, a corresponding `User` entity in our database.

Our ideal interface for the `LaunchRequest` intent handler would be something along these lines:

```ruby
# inside intents/launch_request.rb

intent "LaunchRequest" do
  return tell("Please authenticate Pizza Buddy via the Alexa app.", card: link_account_card) unless request.user_access_token_exists?

  user = User.authenticate(request.user_access_token)
  
  ask("Welcome to Pizza Buddy, #{ user.name }. Would you like a new pizza, or to list orders?")
end
```

Let's set up a new `User` model that can save some key attributes – `name` and `access_token`, to start – to the database. We'll test-drive this implementation:

```ruby
# in spec/user_spec.rb

require 'user'

RSpec.describe User do
  before do
    DataMapper.setup(:default, 'postgres://pizzabuddy@localhost/pizzabuddytest')
    DataMapper.finalize
    User.auto_migrate!
  end

  describe 'Saving to a database' do
    it 'starts out unpersisted' do
      user = User.new
      expect(user.id).to be_nil
    end

    it 'can be persisted' do
      user = User.new(name: "Timmy", access_token: "AccessToken")
      user.save

      persisted_user = User.last
      expect(persisted_user.id).not_to be_nil
      expect(persisted_user.name).to eq "Timmy"
      expect(persisted_user.access_token).to eq "AccessToken"
    end
  end
end
```

Run `rspec`. A simple way to solve the failure is to implement a basic `User` class inside `/lib`:

```ruby
# in lib/user.rb

require 'data_mapper'

class User
  include DataMapper::Resource

  property :id,           Serial
  property :name,         String
  property :access_token, Text
end
```

> We're using the `Text` type for the `access_token` property as Access Tokens can be longer than the `String` type would allow.

We will also need to update `database.rb` to account for the new tables:

```ruby
# in database.rb

require 'data_mapper'
require './lib/pizza'
require './lib/user'

DataMapper.setup(:default, 'postgres://pizzabuddy@localhost/pizzabuddy')
DataMapper.finalize
Pizza.auto_migrate!
User.auto_migrate!
```

Now that we have a basic user entity, serializable to a database, let's implement an `.authenticate` method on the `User` class. We expect this method to either find an existing user, or create a new user, depending on their name and access token:

- If the user does not exist, fetch their name from the Amazon API (using their access token), then save their name and access token to the database. Return the new user.
- If the user already exists (i.e. if there is a user with that name AND access token already in the database), retrieve that existing user.

```ruby
# in spec/user_spec.rb, with some omissions for brevity

require 'user'

RSpec.describe User do
  # ...DataMapper setup...
  # ...pre-existing Database tests...

  describe '.authenticate' do
    let(:amazon_response) do
      amazon_response = {
        name: "Timmy Tales"
      }.to_json
    end
    let(:client) { double(:"Net::HTTP", get: amazon_response) }

    it 'creates a user if one does not exist' do
      expect { User.authenticate("AccessToken", client) }.to change { User.count }.by(1)
    end

    it 'retrieves a user if a one with that name and access token does exist' do
      User.create(name: "Timmy", access_token: "AccessToken")
      
      expect { User.authenticate("AccessToken", client) }.not_to change { User.count }
      expect(User.authenticate("AccessToken", client).name).to eq "Timmy"
      expect(User.authenticate("AccessToken", client).access_token).to eq "AccessToken"
    end
  end
end
```

Let's implement this method in `User`:

```ruby
# in lib/user.rb

require 'data_mapper'
require 'net/http'
require 'uri'
require 'json'

class User
  AMAZON_API_URL = "https://api.amazon.com/user/profile".freeze
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :access_token, String

  def self.authenticate(access_token, client = Net::HTTP)
    uri = URI.parse("#{ AMAZON_API_URL }?access_token=#{ access_token }")
    first_name = JSON.parse(client.get(uri))["profile"]["name"].split(" ").first
    first_or_create(name: first_name, access_token: access_token)
  end
end
```

Returning to our `LaunchRequest` handler:

```ruby
# inside intents/launch_request.rb

intent "LaunchRequest" do
  return tell("Please authenticate Pizza Buddy via the Alexa app.", card: link_account_card) unless request.user_access_token_exists?

  user = User.authenticate(request.user_access_token)
  
  ask("Welcome to Pizza Buddy, #{ user.name }. Would you like a new pizza, or to list orders?")
end
```

Once the user has completed the Account Linking Card, our application will authenticate, then retrieve or save a user.

> Double-check that everything has been correctly set up. Test this step using your Alexa device, by saying "Alexa, launch Pizza Buddy" and checking your Alexa app.

### Managing Pizza ordering per-user

#### 4. Modify the `ConfirmPizzaOrder` intent handler to send an Account Linking Card to the user if they lack an OAuth access token.

You can jump directly to this step by forking from [this commit](https://github.com/sjmog/pizza_buddy/commit/3ab1c24bfddbbcc9885882dcd7a54d0e2ab7a41f).

Just as with the `LaunchRequest` handler, we need users to be authenticated _before_ they confirm their order. Add an authentication guard clause to the first line of the `ConfirmPizzaOrder` intent handler:

```ruby
# in intents/confirm_pizza_order.rb

require './lib/pizza'
require 'active_support/core_ext/array/conversions'

intent "ConfirmPizzaOrder" do
  return tell("To confirm your order, please authenticate Pizza Buddy via the Alexa app.", card: link_account_card) unless request.user_access_token_exists?

  pizza = Pizza.new(size: request.session_attribute('size'), toppings: request.session_attribute('toppings'))
  pizza.save

  response_text = ["Thanks! Your #{ pizza.size } pizza with #{ pizza.toppings.to_sentence } is on ",
                   "its way to you. Your order ID is #{ pizza.id }. Thank you for using Pizza Buddy!"].join
  
  card_title = "Your Pizza Order ##{ pizza.id }"
  card_body = "You ordered a #{ pizza.size } pizza with #{ pizza.toppings.to_sentence }!"
  card_image = "https://image.ibb.co/jeRZLv/alexa_pizza.png"
  pizza_card = card(card_title, card_body, card_image)

  tell(response_text, card: pizza_card)
end
```

#### 5. Modify pizza saving in the `ConfirmPizzaOrder` intent handler to ensure that the saved pizza `belongs_to` the authenticated user.

Users should own any pizzas they have ordered. Implement a `has_many` relationship between `User` and `Pizza`:

```ruby
# in lib/user.rb, with omissions for brevity
require_relative './pizza'

class User
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :access_token, String

  # implement a one-to-many relationship
  has n,   :pizzas

  # ...rest of class...
end
```

Also, implement the reflective relationship, so `Pizza` instances can `belong_to` a `User`:

```ruby
# in lib/pizza.rb, with omissions for brevity
require_relative './user'

class Pizza
  include DataMapper::Resource

  property   :id, Serial
  property   :size, String
  property   :toppings, PgArray

  # implement a belongs_to relationship
  belongs_to :user

  # ...rest of class...
end
```

We will need to update the `spec/pizza_spec.rb` tests for Pizza to reflect this new requirement:

```ruby
# in spec/pizza_spec.rb, with omissions for brevity
require 'pizza'

RSpec.describe Pizza do
  # ... rest of tests ...

  describe 'Saving to a database' do
    it 'starts out unpersisted' do
      pizza = Pizza.new(size: 'small', toppings: ['cheese', 'ham'])
      expect(pizza.id).to be_nil
    end

    it 'can be persisted' do
      # Add a user_id parameter here, to mock the required user this pizza must belong_to
      pizza = Pizza.new(size: 'small', toppings: ['cheese', 'ham'], user_id: 1)
      pizza.save

      expect(pizza.id).not_to be_nil
    end
  end
end
```

Modify the `ConfirmPizzaOrder` intent, so created pizzas automatically belong to an individual user:

```ruby
require './lib/pizza'
require 'active_support/core_ext/array/conversions'

intent "ConfirmPizzaOrder" do
  return tell("To confirm your order, please authenticate Pizza Buddy via the Alexa app.", card: link_account_card) unless request.user_access_token_exists?

  user = User.authenticate(request.user_access_token)
  # any new pizzas must belong to the authenticated user
  pizza = user.pizzas.new(size: request.session_attribute('size'), toppings: request.session_attribute('toppings'))
  pizza.save

  response_text = ["Thanks! Your #{ pizza.size } pizza with #{ pizza.toppings.to_sentence } is on ",
                   "its way to you. Your order ID is #{ pizza.id }. Thank you for using Pizza Buddy!"].join
  
  card_title = "Your Pizza Order ##{ pizza.id }"
  card_body = "You ordered a #{ pizza.size } pizza with #{ pizza.toppings.to_sentence }!"
  card_image = "https://image.ibb.co/jeRZLv/alexa_pizza.png"
  pizza_card = card(card_title, card_body, card_image)

  tell(response_text, card: pizza_card)
end
```

Ordered `Pizza`s now belong to the authenticated `User` that ordered them.

#### 6. Modify the `ListOrders` intent handler to list only pizzas belonging to the currently-authenticated user.

Unauthenticated users should not be able to list any orders. Authenticated users should only be able to list orders that they have made.

Implement an authentication guard clause in the `ListOrders` intent handler to block unauthenticated users:

```ruby
# in intents/list_orders.rb

require './lib/pizza'

intent "ListOrders" do
  return tell("To list your orders, please authenticate Pizza Buddy via the Alexa app.", card: link_account_card) unless request.user_access_token_exists?

  orders = Pizza.first(4).map { |order| "a #{ order.size } pizza with #{ order.toppings.to_sentence }" }
  response_text = ["There are #{ user.pizzas.count } orders. ",
                   "#{ orders.to_sentence }. ",
                   "You can ask to list orders again, or order a pizza."].join

  ask(response_text)
end
```

To ensure that users can only list orders that they have made, authenticate users with an access token, and scope the query to pizzas belonging to the authenticated user:

```ruby
require './lib/pizza'

intent "ListOrders" do
  return tell("To list your orders, please authenticate Pizza Buddy via the Alexa app.", card: link_account_card) unless request.user_access_token_exists?

  # Authenticate users with an access token
  user = User.authenticate(request.user_access_token)

  # Scope the pizza query to pizzas belonging to the authenticated user
  if user.pizzas.any?
    orders = user.pizzas.first(4).map { |order| "a #{ order.size } pizza with #{ order.toppings.to_sentence }" }
    response_text = ["You have made #{ user.pizzas.count } orders. ",
                     "#{ orders.to_sentence }. ",
                     "You can ask to list orders again, or order a pizza."].join
  else
    response_text = "You haven't made any orders yet. To start, say 'order a pizza'."
  end

  ask(response_text)
end
```

## Wrapping up

This concludes module 6: authenticating skill users with OAuth. You can fork the completed application at the end of this module from [this commit](https://github.com/sjmog/pizza_buddy/commit/9fcf4887e56a079418e7675c0d13bafbc5432853).

We have now covered all aspects required to build an advanced skill using Alexa and Ruby. Now, go build your own!