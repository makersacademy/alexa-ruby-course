intent("AMAZON.StartOverIntent") do
  response_text = "OK, what movie would you like to know about?"
  
  response.build(response_text: response_text, start_over: true)
end
