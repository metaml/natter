#!/usr/bin/env python

import api_key as ak
import gradio as g
import openai

def chatbot(input):
  if input:
    messages.append({"role": "user", "content": input})
    chat = openai.ChatCompletion.create(
      model="gpt-3.5-turbo", messages=messages
    )
    reply = chat.choices[0].message.content
    messages.append({"role": "assistant", "content": reply})
    return reply

if __name__ == "__main__":
  openai.api_key = ak.openai()
  messages = [
    {"role": "system", "content": "You are a helpful and kind AI Assistant."},
  ]

  inputs = g.Textbox(lines=7, label="Hal")
  outputs = g.Textbox(label="reply")

  nat = g.Interface(fn=chatbot,
                    inputs=inputs,
                    outputs=outputs,
                    title="AIP",
                    description="Hello, Dave",
                    theme="compact"
                    ).launch(share=True)
  nat.launch()

  
