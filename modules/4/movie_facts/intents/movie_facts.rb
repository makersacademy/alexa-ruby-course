require './lib/movie'

intent("MovieFacts") do
  movie = Movie.find(request.slot_value("Movie"))
  response_text = movie.plot_synopsis

  response.build(response_text: response_text, session_attributes: { movieTitle: movie.title })
end