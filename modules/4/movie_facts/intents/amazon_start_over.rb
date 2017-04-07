intent "AMAZON.StartOverIntent" do
  response.build(response_text: "OK, what movie would you like to know about?", start_over: true)
end
