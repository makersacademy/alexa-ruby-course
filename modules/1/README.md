# Alexa Module 1: Hello World

This module introduces:

- Intent Schemas
- Utterances
- Alexa communication paradigm
- Tunnelling a local application using ngrok over HTTPS
- Connecting Alexa to a local development environment
- Alexa-style JSON requests and responses

## Contents

In this module, there are the following:

- [Challenges](challenges/) (for use by coaches delivering the content)
- [Challenge Walkthroughs](walkthroughs/) (for use by coaches delivering the content)
- [Full Markdown Walkthrough](walkthrough.md)
- [Full PDF Walkthrough](walkthrough.pdf)
- [Images](images/) associated with this module

## Overview

During this module, readers will construct a simple Skill, called 'Hello World'. While building this skill, readers come to understand how the above concepts work and play together. This module uses:

- Sinatra
- Ruby's JSON library

This module deliberately does not use any Ruby framework for Sinatra. Instead, it interfaces directly with the JSON requests and responses that Amazon sends and receives from an application. The intention is to help readers to understand the underlying principles behind how an Alexa Skill works, using only what they know, before introducing abstraction frameworks in subsequent modules. This has the following advantages:

- Readers should already be familiar with sending and receiving JSON packets through requests and responses
- Readers are informed about the underlying structure of requests and responses by interfacing with them directly, giving them more flexibility when implementing Skills in future
- Readers are not tied to any one Open Source framework, which enhances the longevity of these materials (in the event the framework is not maintained or superceded).

By the end of this module, readers are prepared to create a Skill that takes parameters to Utterances (that is, uses Slots).
