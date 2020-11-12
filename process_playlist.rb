#!/usr/bin/env ruby

require 'json'

=begin
Keep it simple. Focus on implementing just the requirements. 
Your application doesn't need to handle any other operations.

Readability is key. Convey your intent with clear, organized code and with 
comments where appropriate.

Don't worry about creating a UI, DB, server, or deployment.
=end

module Main

  def self.run
    if ARGV.length < 1
      puts "Usage: process_playlist.rb changes.json"
      exit -1
    end

    mix_tape = MixTape.new("mixtape-data.json")

    mix_tape.injest_mixtape_data

    changes_file = ARGV[0]

    mix_tape.process_changes(changes_file)
    mix_tape.print_updated_state
  end

end

class MixTape

  User = Struct.new(:id, :name)
  Song = Struct.new(:id, :artist, :title)
  PlayList = Struct.new(:id, :user, :songs)

  def initialize(data_file)
    # check if file is valid ??
    @data_file = data_file

    @users = {}
    @playlists = []
    @songs = []
  end

  def process_changes(changes_file)
    puts "process_changes for #{changes_file}"
  end

  def print_updated_state
    puts "print_updated_state"
    puts "USERS: #{@users.inspect}"
    puts "SONGS: #{@songs.inspect}"
    puts "PlayLists: #{@playlists.inspect}"
  end

  def injest_mixtape_data
    puts "processing #{@data_file}"
    mix_tape_file = File.read(@data_file)
    mix_tape_json = JSON.parse(mix_tape_file)

    @users = process_users(mix_tape_json["users"])
    @songs = process_songs(mix_tape_json["songs"])
    @playlists = process_playlists(mix_tape_json["playlists"])

    puts "found #{@users.size} users."
    puts "found #{@songs.size} songs."
    puts "found #{@playlists.size} playlists."
  end

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

  #######
  private
  #######

  def find_user_by_id(id)
    @users[id]
  end

  def find_song_by_id(id)
    @songs[id]
  end

end

Main.run
