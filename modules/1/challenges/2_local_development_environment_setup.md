# 2: Setting up an Alexa-compatible local development environment

In this challenge, we will set up a local development environment which can talk with Amazon's Alexa Service.

To complete this challenge, **set up a new Sinatra Application with an Endpoint accessible to the World Wide Web.**

> We suggest building a local environment that uses a Tunnelling Service such as [ngrok](https://ngrok.com) to open an HTTPS connection to the World Wide Web. If you would prefer to take an alternative route: say, to set up a remote development server using a host, please feel free to do so. In that case, you can [skip to the next challenge](3_linking_amazon_to_our_endpoint.md).

### New Concepts

- Tunnelling a local application using ngrok over HTTPS

### To complete this challenge, you will need to:

- [ ] Set up a [Sinatra](http://www.sinatrarb.com/) application with a single route, `POST '/'`.
- [ ] Inside this route, print the contents of any incoming `request.body` to the command line.
- [ ] Set up [ngrok](https://ngrok.com) to expose your local Sinatra application to the Internet.
- [ ] Start your server, and make a note of the HTTPS endpoint given by ngrok.

### Walkthrough

Ready for a step-by-step guide? [Head to the Walkthrough for this Challenge](walkthroughs/2_local_development_environment_setup.md).