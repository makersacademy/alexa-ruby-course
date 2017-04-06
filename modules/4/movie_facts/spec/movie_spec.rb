require 'movie'

RSpec.describe Movie do
  describe '.find' do
    it 'delegates finding a movie to an Imdb client search' do
      client = double("Imdb::Search")
      expect(client).to receive_message_chain(:new, :movies, :first)

      described_class.find("Some Movie Title", client)
    end
  end

  describe '#plot_synopsis' do
    it 'returnst the ploy synopsis of the underlying record' do
      imdb_record = double("Imdb::Movie", plot_synopsis: "This Movie is great!")

      expect(described_class.new(imdb_record).plot_synopsis).to eq "This Movie is great!"
    end

    it 'trims the synopsis to 140 characters' do
      over_length_synopsis = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque interdum rutrum sodales. Nullam mattis fermentum libero, noon volutpat."
      imdb_record = double("Imdb::Movie", plot_synopsis: over_length_synopsis)

      expect(described_class.new(imdb_record).plot_synopsis.length).to eq 140
    end
  end

  describe '#cast_list' do
    it 'returns a human-readable string of cast members' do
      imdb_record = double("Imdb::Movie", title: "Movie", cast_members: ["Famous star 1", "Famous star 2"])

      expect(described_class.new(imdb_record).cast_members).to eq "Movie starred Famous star 1, Famous star 2"
    end

    it 'trims the cast list to 140 characters' do
      over_length_cast_members = ["Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque interdum rutrum sodales. Nullam mattis fermentum libero, noon volutpat."]
      imdb_record = double("Imdb::Movie", title: "Movie", cast_members: over_length_cast_members)

      expect(described_class.new(imdb_record).cast_members.length).to eq 140
    end
  end

  describe '#directors' do
    it 'returns a human-readable string of director names' do
      imdb_record = double("Imdb::Movie", title: "Movie", director: ["Famous director"])

      expect(described_class.new(imdb_record).directors).to eq "Movie was directed by Famous director"
    end

    it 'trims the director string to 140 characters' do
      over_length_directors = ["Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque interdum rutrum sodales. Nullam mattis fermentum libero, noon volutpat."]
      imdb_record = double("Imdb::Movie", title: "Movie", director: over_length_directors)

      expect(described_class.new(imdb_record).directors.length).to eq 140
    end
  end
end