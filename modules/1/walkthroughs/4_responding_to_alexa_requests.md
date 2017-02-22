# Walkthrough 4: Responding to Alexa Requests

Now we have built an Alexa development Skill ([Challenge 1](../challenges/1_setting_up_a_new_skill.md)), built a local development server with an endpoint tunnelled via HTTPS ([Challenge 2](../challenges/2_local_development_setup.md)), and can make requests from Amazon to our local development server through that endpoint ([Challenge 3](../challenges/3_linking_amazon_to_our_endpoint.md)).

Our final step is to construct a response from our endpoint such that Amazon can interpret the response to make Alexa say ‘Hello World’ to us.

##### Building the JSON Response

Amazon sends and receives JSON responses in a particular format. Let's set that up here.

- `require 'json'` at the top of `server.rb`
- Replace the body of our Sinatra POST ‘/‘ route with the smallest possible response from the [Alexa Skills Kill Response Body Documentation](https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/alexa-skills-kit-interface-reference#response-body-syntax):

```ruby
# inside server.rb

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

There are a few parts to this JSON response object:

- `version` (string): required. Allows you to version your responses.
- `response` (object): required. Tells Alexa how to respond: including speech, cards, and prompts for more information.
  - `outputSpeech` (object). Tells Alexa what to say.
    - `type` (string) required. Tells Alexa to use Plain Text speech, where Alexa will guess pronunciation, or [Speech Synthesis Markup Language](https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/speech-synthesis-markup-language-ssml-reference) (SSML), where you can specify pronunciation very tightly.
      - **EXTRA CREDIT**: Change the response to use custom pronunciation using SSML.
    - `text` (string) required. Tells Alexa exactly what to respond with.
      - **EXTRA CREDIT**: Play around with this response, restarting the server and sending an Intent Request from the Service Simulator each time.

##### Testing our Response in the Service Simulator...and beyond!

Now that we've built a JSON response, we can restart the server, and test out the new response in the Service Simulator.

If you would like to try your new Hello World skill out live, hit ‘Next’ to complete the Publishing Information, 'Save', and download the skill in your Alexa App!

[Back to the Welcome](../challenges/0_welcome.md)