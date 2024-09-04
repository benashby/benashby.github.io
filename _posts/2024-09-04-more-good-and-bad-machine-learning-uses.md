---
layout: post
title: More Good and Bad Machine Learning Uses
categories: [Artificial Intelligence, Machine Learning]
excerpt: Exploring additional examples of effective and ineffective applications of machine learning.
---

In my previous post, I discussed the capabilities and limitations of artificial intelligence (AI) and machine learning (ML). I mentioned that AI is good at fast and automatic tasks but struggles with slow and deliberate ones. In this post, I will explore more examples of good and bad uses of machine learning.

Example of something that AI and Machine Learning is well suited for is taking a picture of the road in front of your car, possibly along with Lidar and Radar data, and determine the position of vehicles in front of you. This is a fast and automatic task that AI excels at.

And example of something related to autonomous driving that AI and Machine Learning would not be good at is understanding the intent of some who is gesturing to you in front of your car.  For example, a constrcutor worker waving you down to stop, a hitchhiker waving you down to pick them up, or a cycling who is signaling their intent to execute a turn.  An image of each of these examples woould be a picture of person making a similar hand gesture, but AI would not be able to understand the context and intent of the person in the picture.  We as humans can draw on a lifetime of experience to understand the context and intent of the person in the picture, but AI would not be able to do this.

Another example of where AI and Machine Learning can fall short is when it is asked to do an A -> B mapping on a piece of data that has different variables than the data that it has been trained on.  For example, if an autonomous driving AI was trained on 10 thousand images of SUVs and then asked to identify a vehicle in front of it that is a motorcycle, it would not be able to do this.  In the medical space, if an AI is trained on thousand clean and high resolution chest x-rays and then given an x-ray that is at a different angle or perhaps has a scratch on it, the AI would not be able to properly map the data to the correct output.  A human would be able to use their intuition and experience to know what pieces of the input are irrelevant, such as a scratch on a xray, and disregard it when making a diagnosis.  AI would not be able to do this.