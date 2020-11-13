require 'json'
require_relative 'model'
module InjestMixtape

  include Model
  def injest_mixtape_data

    # TODO check if file is valid ??
    puts "processing #{@data_file}"
    mix_tape_file = File.read(@data_file)
    mix_tape_json = JSON.parse(mix_tape_file)

    # TODO : validate JSON file schema for all input files

    @users = process_users(mix_tape_json["users"])
    @songs = process_songs(mix_tape_json["songs"])
    @playlists = process_playlists(mix_tape_json["playlists"])

    puts "found #{@users.size} users."
    puts "found #{@songs.size} songs."
    puts "found #{@playlists.size} playlists."
  end

  #######
  private
  #######

  def process_users(json_arr)
    users = {}
    unless json_arr.nil?
      json_arr.each do |user|
        users[user["id"]] = User.new(user["id"], user["name"])
      end
    end

    users
  end

  def process_songs(json_arr)
    songs = {}
    unless json_arr.nil?
      json_arr.each do |song|
        songs[song["id"]] = Song.new(song["id"], song["artist"], song["title"])
      end
    end

    songs
  end

  # passing in users and songs
  def process_playlists(json_arr)
    playlists = {}
    unless json_arr.nil?
      json_arr.each do |playlist|
        playlist_id = playlist["id"]
        user_id = playlist["user_id"]
        user = find_user_by_id(user_id)

        if user.nil?
          STDERR.puts "Skipping playlist #{playlist} because it has invalid user id #{user_id}"
          next
        end

        songs = []
        playlist["song_ids"].each do |song_id|
          song = find_song_by_id(song_id)

          if song.nil?
            STDERR.puts "Skipping invalid song with id #{song_id} from #{playlist}"
            next
          end

          songs << song
        end

        playlists[playlist_id] = PlayList.new(playlist_id, user, songs)
      end
    end

    playlists
  end

end
