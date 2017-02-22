# Walkthrough 3: Linking Amazon to our application's endpoint

Our third step is to link the Skill we set up on Amazon (1) with the Tunnel Endpoint (2) so our Skill can send requests to our local application.

##### Configuring the Endpoint in the Alexa Skills Portal

> When Amazon invokes an Intent, Amazon sends a `POST` request to the specified _Endpoint_ (web address).

Head back to your Alexa Skill (for which you just entered Intents and Utterances). Hit Next, then set up the Endpoint.

- Use HTTPS, not Lambda (no Ruby on Lambda)
  - Geographical Region: Europe
  - Paste the Endpoint to your application into the text input field

> If using ngrok, your Endpoint is the URL you copied, starting with ‘https’ and ending with ‘.ngrok.io’.

- You won't need Account Linking for this application.

![](../images/Screen%20Shot%202017-02-22%20at%2012.31.52.png)

##### Configuring SSL

Amazon Alexa only sends requests to secure Endpoints: ones secured using an SSL certificate (denoted by the 'S' in HTTPS). Since we used ngrok to set up our HTTPS Endpoint, we can use ngrok's 'wildcard' certificate instead of providing our own.

- If you used ngrok to set up a Tunnel, select ‘My development endpoint is a sub-domain of a domain that has a wildcard certificate from a certificate authority’.
- Hit 'Next' again.

##### Testing in the Service Simulator

The _Service Simulator_ allows you to try out utterances. Once you’ve written an utterance into the Service Simulator, you can send test requests to the application endpoint you defined. You can see your application’s response to each request that you send.

- Use the Service Simulator to test that the `say hello world` utterance causes Amazon to send an Intent Request to your local application, and observe that the request body printed to the command-line matches the JSON request sent in the Service Simulator.

You’ve now hooked up your local development environment to an Alexa Skill!

[On to the next Challenge](../challenges/4_responding_to_alexa_requests.md)
[Back to the Welcome](../challenges/0_welcome.md)