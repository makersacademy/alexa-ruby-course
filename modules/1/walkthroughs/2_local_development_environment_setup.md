# Walkthrough 2: Setting up an Alexa-compatible local development environment

Our second step is to set up our local Ruby application, ready to receive encrypted requests from Amazon’s servers (i.e. HTTP requests over SSL, or ‘HTTPS’ requests).

We will walk through setting up a Ruby server using Sinatra, running locally, and capable of receiving HTTPS requests through a Tunnel.

Alternatively, you could set up a **remote** development server using [Heroku](http://heroku.com) (with [Heroku SSL](https://devcenter.heroku.com/articles/ssl)), [Amazon Elastic Beanstalk](https://aws.amazon.com/elasticbeanstalk/?sc_channel=PS&sc_campaign=acquisition_UK&sc_publisher=google&sc_medium=beanstalk_b&sc_content=elastic_beanstalk_e&sc_detail=elastic%20beanstalk&sc_category=beanstalk&sc_segment=159760119038&sc_matchtype=e&sc_country=UK&s_kwcid=AL!4422!3!159760119038!e!!g!!elastic%20beanstalk&ef_id=WKgq9QAABVYkDTpR:20170222115859:s) (with a [self-signed SSL certificate](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/configuring-https-ssl.html)), or any other method you can think of.

We’re going to use [ngrok](https://ngrok.com/) to Tunnel to a local development server.

##### Setting up a Sinatra application

- Make the directory with `mkdir hello_world_app`
- Head into the directory with `cd hello_world_app`
- Set up a Ruby application with `bundle init` (you may need to install Bundler with `gem install bundler` first)
- Add the Sinatra gem to your Gemfile, by adding the line `gem 'sinatra'`
- Install Sinatra to your project using `bundle install`
- Create a server file with `touch server.rb`
- For now, create a single `POST` route, `'/'`, that prints out the request body we are going to receive from Amazon:

```ruby
# inside server.rb

require 'sinatra'

post '/' do
 p request.body.read
end
```

##### Opening your Sinatra application to the Internet using ngrok

- Download the appropriate ngrok package for your Operating System from the [ngrok downloads page](https://ngrok.com/download)
- Unzip the package and transfer the executable to your `hello_world_app` directory
- Start ngrok using `./ngrok http 4567`
- Copy to the clipboard (`command-C`) the URL starting ‘https’ and ending ‘.ngrok.io’ from your ngrok Terminal
- In a second Terminal, start your Sinatra application using `ruby server.rb`.

[On to the next Challenge](../challenges/3_linking_amazon_to_our_endpoint.md)
[Back to the Welcome](../challenges/0_welcome.md)