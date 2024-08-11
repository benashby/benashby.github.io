---
layout: post
title:  Beginning AI
categories: [Artificial Intelligence, Machine Learning]
excerpt: Notes on the basics of Artificial Intelligence and Machine Learning.
---

_The following are notes that I took while taking beginning AI courses_

## AI Terminology

### ANI vs Generative AI

Before Generative AI there was "Artificial Narrow Intelligence" (ANI).  ANI is the most common form of AI in the world today.  It is designed to perform a single task.  ANI is not capable of generalizing beyond the task it was designed for.  It is also not capable of learning new tasks on its own.

Examples of ANI include:
* A "Smart Speaker"
* A self-driving car
* Spam detection
* Image Recognition

Examples of Generative AI include:
* An LLM (Large Language Model) like GPT-4
* DeepArt
* Code Generation

Generative AI differs from ANI in that it is capable of generating new data.  It is able to learn from data and generate new data that is similar to the data it was trained on.  This is in comparison to ANI which is designed to take input data and produce output data.

### Machine Learning vs Data Science

#### Machine Learning:

A machine learning system is a system that takes input and produces output.  The system learns from the input data and uses that knowledge to make predictions about new data.  Machine learning is a subset of data science.  Data science is the broader field that encompasses machine learning, statistics, and other techniques for analyzing data.

"Field of study that gives computers the ability to learn without being explicitly programmed." - Arthur Samuel

#### Data Science:

Data Science is the process that involves collecting, cleaning, and analyzing data to extract insights and make predictions.  Machine learning is a subset of data science that involves training models to make predictions based on data.  For example, data science could extract insights from home pricing data to determine that, for example, the square footage of a house has a much greater impact on price than the number of bedrooms.

Output from a data science projects are often human conumable resources like slide decks, reports, and dashboards.  Machine learning projects often output models that can be used to make predictions on new data.



## Machine Learning

### Supervised Learning
Supervised learning is the most common type of machine learning.  It involves training a model on a labeled dataset.  The model learns to map inputs to outputs based on the examples it is given.  The goal is to learn a general rule that can be applied to new, unseen data.

Examples:
* Map an email to spam or not spam.
* Map an audio input to a transcript
* Map an image to a label
* Map a patient's symptoms to a disease
* A very lucrative example is mapping a user's behavior to an ad click
* A chatbot, like Bard or GPT-3, is a supervised learning model that has consumed massive amounts of text data to learn how to generate "the next word" in a sentence.

### How does an LLM work at a high level?

A language model undergoes supervised learning by training on a large dataset of text.  The model learns to predict the next word in a sentence based on the words that came before it.  The model is trained to minimize the error between the predicted word and the actual word.

An training example is a sentence like "The cat sat on the ____."  The model predicts the next word, "mat", and is trained to minimize the error between the predicted word and the actual word, "mat".  The model is able to predict the next work is "mat" because it has seen many examples of the word "mat" following the words "The cat sat on the".

### Why has LLM become so popular recently?

Supervised machine learning has been around for a long time, but it has suffered from asymptoic performance increases.  This means that as the amount of data increases, the performance of the model plateaus.  One advancement that has helped to break this plataue is the use of Nerual Networks.  Neural Networks are a type of model that can learn from data and generalize to new data.  They are able to learn complex patterns in the data that are not easily captured by traditional models.

### Traditional Machine Learning vs Neural Networks

Traditional machine learning models are based on a set of rules that are hand-crafted by the modeler through a process known as "Feature Extraction".  These rules are used to map inputs to outputs.  Neural Networks, on the other hand, learn the rules from the data.  They are able to learn complex patterns in the data that are not easily captured by traditional models.  

The performance of a neural network scales with the amount of data it is trained on.  Neural networks tend to benefit more from massive amounts of data than traditional models.  This is because they are able to learn complex patterns in the data that are not easily captured by traditional models.


### Datasets

Datasets are the lifeblood of machine learning.  They are used to train models to perform tasks like image recognition, speech recognition, and language translation.  Datasets are typically labeled with the correct answer so that the model can learn to predict the correct answer.  The more data you have, the better your model will perform.

Consider the following dataset defining the relationship between a house's square footage, the number of bedrooms, and its price:

| Square Footage | Bedrooms | Price |
|----------------|----------|-------|
| 1000           | 2        | $200k |
| 1500           | 3        | $300k |
| 2000           | 4        | $400k |
| 2500           | 5        | $500k |

The goal of a machine learning model is to learn a function that maps the input features (square footage and number of bedrooms) to the output (price).  The model learns this function by training on the dataset.

The input of this model would be a composite of the square footage and the number of bedrooms.  The output would be the price of the house.  The model learns to predict the price of a house based on its square footage and number of bedrooms.

### Acquiring Data

There are many ways to acquire data for machine learning.  Some common sources of data include:

* Public datasets: There are many public datasets available for machine learning.  These datasets are often used for research purposes and are freely available to the public.
* Manual Labeling: You can manually label data by hand.  This is a time-consuming process, but it can be useful if you need a specific type of data that is not available in a public dataset.
* Observing User Behavior: You can observe user behavior to collect data.  For example, you can track how users interact with your website or app to collect data on their preferences and habits.
* Capturing machine's data: You can capture data from sensors or other devices to collect data.  For example, you can capture data from a camera to collect images for a computer vision model.

### Examples of Misusing Data

There are many ways to misuse data in machine learning.  Some common examples include:

* Collecting data randomly without a clear goal in mind
  * This can lead to a dataset that is not useful for training a model
  * You should start training models as soon as you start collecting data to ensure that the data is useful
  * Getting feedback from AI models early and often leads to better data collection
* Collecting bad data
  * Straight up incorrect data
  * Incomplete data
    * This can make it very difficult for AI engineers to train models or clean up the data
* Collecting multiple types of data
  * _Unstructured Data_ such as a collection of images, text, and audio

Tomorrow I will study what makes a company and AI company, and what machine learning can and cannot do.