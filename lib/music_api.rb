require 'httparty'

class MusicApi
  include HTTParty

  base_uri 'http://ws.audioscrobbler.com/'

  def options
    {api_key: ''}
  end

  def artist_info(title)
    artist_search_options = {
        artist: title,
        method: 'artist.search',
        format: 'json'
    }
    search_options = options.merge(artist_search_options)
    response = self.class.get('/2.0/?'+URI.encode_www_form(search_options))
    return process_artist_info_response(response)
  end

  def metadata_by_id(id)
    return self.class.get("/artist/#{id}?"+URI.encode_www_form(options))
  end

  def albums_by_mbid(mbid)
    search_options = {
      mbid: mbid,
      method: 'artist.gettopalbums',
      format: 'json'
    }
    response = self.class.get('/2.0/?'+URI.encode_www_form(options.merge(search_options)))
    process_albums_info_response(response)
  end

  def tracks_by_mbid(mbid)
    search_options = {
        mbid: mbid,
        method: 'artist.gettoptracks',
        format: 'json'
    }
    response = self.class.get('/2.0/?'+URI.encode_www_form(options.merge(search_options)))
    process_tracks_info_response(response)
  end

  def similar_artists_by_mbid(mbid)
    search_options = {
        mbid: mbid,
        method: 'artist.getsimilar',
        format: 'json'
    }
    response = self.class.get('/2.0/?'+URI.encode_www_form(options.merge(search_options)))
    process_similar_artists_info_response(response)
  end

  private

  def any_results?(response)
    response['results']['artistmatches'].first[1].any?
  end

  def get_first_result(response)
    response['results']['artistmatches'].first[1][0]
  end

  def process_artist_info_response(response)
    if any_results?(response)
      band = get_first_result(response)
      {
        name: band['name'],
        mbid: band['mbid']
      }
    end
  end

  def process_albums_info_response(response)
    response['topalbums']['album'][0..9].map do |album|
      album['name']
    end
  end

  def process_tracks_info_response(response)
    response['toptracks']['track'][0..9].map do |track|
      {
          name: track['name'],
          url: track['url']
      }
    end
  end

  def process_similar_artists_info_response(response)
    response['similarartists']['artist'][0..4].map do |artist|
      artist['name']
    end
  end
end