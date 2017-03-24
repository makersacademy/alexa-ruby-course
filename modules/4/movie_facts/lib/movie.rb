require 'imdb'

class Movie
  def self.find(movie_title, client = Imdb::Search)
    movie_list = client.new(movie_title).movies
    movie_list.first
  end
end