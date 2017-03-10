# Alexa Module 2: Fact-Checking

This module introduces:

- Slots
- Custom Slot Types

## Contents

In this module, there are the following:

- [Challenges](challenges/) (for use by coaches delivering the content) :construction:
- [Challenge Walkthroughs](walkthroughs/) (for use by coaches delivering the content) :construction:
- [Full Markdown Walkthrough](walkthrough.md)

## Overview

During this module, readers will construct a simple Skill, called 'Number Facts'. While building this skill, readers come to understand how the above concepts work and play together. This module uses:

- Sinatra
- Ruby's JSON library
- Ruby's HTTP library
- the [Numbers API](http://numbersapi.com/)

This module deliberately does not use any Ruby framework for Sinatra. Instead, it interfaces directly with the JSON requests and responses that Amazon sends and receives from an application. The intention is to help readers to understand the underlying principles behind how an Alexa Skill works, using only what they know, before introducing abstraction frameworks in subsequent modules. This has the following advantages:

- Readers should already be familiar with sending and receiving JSON packets through requests and responses
- Readers are informed about the underlying structure of requests and responses by interfacing with them directly, giving them more flexibility when implementing Skills in future
- Readers are not tied to any one Open Source framework, which enhances the longevity of these materials (in the event the framework is not maintained or superceded).

By the end of this module, readers are prepared to create a Skill that involves conversation (that is, uses Sessions).
