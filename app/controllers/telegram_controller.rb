require 'music_api'

class TelegramController < Telegram::Bot::UpdatesController

  include Telegram::Bot::UpdatesController::MessageContext

  use_session!

  context_to_action!

  def write(name, mbid)
    session[:name] = name
    session[:mbid] = mbid
  end

  def current_data
    {
      name: session[:name],
      mbid: session[:mbid]
    }
  end

  def start(*)
    respond_with :message, text: "Hi, #{from['first_name']}! Put your band below:"
  end

  def help(*)
    respond_with :message, text: 'Need help? Try /start !'
  end

  def albums(*)
    if mbid = current_data[:mbid]
      info = ::MusicApi.new.albums_by_mbid(mbid)
      respond_with_albums(info)
    else
      respond_with_not_found_error
    end
  end

  def tracks(*)
    if mbid = current_data[:mbid]
      info = ::MusicApi.new.tracks_by_mbid(mbid)
      respond_with_tracks(info)
    else
      respond_with_not_found_error
    end
  end

  def similar_artists(*)
    if mbid = current_data[:mbid]
      info = ::MusicApi.new.similar_artists_by_mbid(mbid)
      respond_with_similar_artists(info)
    else
      respond_with_not_found_error
    end
  end

  def message(message)
    info = ::MusicApi.new.artist_info(message['text'])
    if info
      write(info[:name], info[:mbid])
      if current_data[:name]
        respond_with_active
      else
        respond_with_inactive
      end
    else
      respond_with_not_found_error
    end
  end

  def respond_with_active
    respond_with :message,
                 text: "Your current band: #{current_data[:name]}\nChoose action below!",
                      reply_markup: custom_markup
  end

  def custom_markup
    {
        keyboard: [
            [
                {text: '/albums'},
                {text: '/tracks'},
                {text: '/similar_artists'}
            ],
            [{text: 'Search web', url: "https://google.by/search?q=#{current_data[:name]}"}],
        ],
        one_time_keyboard: true
    }
  end

  def respond_with_inactive
    respond_with :message, text: 'Write your band below, please!'
  end

  def respond_with_albums(albums)
    respond_with :message,
                 text: albums.join("\n--------------\n"),
                      reply_markup: custom_markup
  end


  def respond_with_tracks(tracks)
    respond_with :message,
                 text: prepare_tracks(tracks),
                 reply_markup: custom_markup
  end

  def prepare_tracks(tracks)
    tracks.reduce("") do |string, track|
      string += "#{track[:name]}\n"
      string += "#{track[:url]}\n----------------\n"
      string
    end
  end

  def respond_with_similar_artists(artists)
    respond_with :message,
                 text: 'Here are similar artists! Click below to switch:',
                      reply_markup: {
                          keyboard: [
                              artists.map {|artist| {text: artist}},
                          ],
                          one_time_keyboard: true
                      }
  end

  def respond_with_not_found_error
    respond_with :message, text: 'We can\'t find your band! Please try another one!'
  end

end