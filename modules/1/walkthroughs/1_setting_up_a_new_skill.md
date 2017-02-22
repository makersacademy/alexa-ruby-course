# Walkthrough 1: Setting up a new Alexa Skill

Our first step is to set up the Skill on Amazon.

- Sign up, then sign in to the [Amazon Alexa Developer Dashboard](https://developer.amazon.com/alexa)
- Get Started with the Alexa Skills Kit: 
![Get Started with the Alexa Skills Kit](../images/Screen%20Shot%202017-02-22%20at%2011.39.31.png)

- ‘Add a New Skill’: 
![](../images/Screen%20Shot%202017-02-22%20at%2011.41.38.png)

- Set up the app:
  - Language
  - Name (‘Hello World’)
  - Invocation Name (‘Hello World’)
![](../images/Screen%20Shot%202017-02-22%20at%2011.42.44.png)

##### Intent Schemas

Now we have a new skill, let's construct the **Intent Schema**.
> The Intent Schema lists all the possible requests Amazon can make to your application.

```json
  {
    "intents": [
      {
        "intent": "HelloWorld"
      }
    ]
  }
```

The minimal Intent Schema is a JSON object, with a single property: `intents`. This property lists all the actions an Alexa Skill can take. Each action is a JSON object, with a single property: `intent`. The `intent` property gives the name of the intent.

##### Utterances

Now we have the Intent Schema, let's make the **Utterances**. Utterances map Intents to phrases spoken by the user. They are written in the following form:

```
IntentName utterance
```

In our case, we have only one Intent: `HelloWorld`, and we'd like the user to say the following:

> Alexa, say hello world.

Our Utterances are:

```
HelloWorld say hello world
```

We've now set up our Skill on Amazon's Alexa Developer Portal.

[On to the next Challenge](../challenges/2_local_development_environment_setup.md)
[Back to the Welcome](../challenges/0_welcome.md)