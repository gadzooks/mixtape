#!/usr/bin/env ruby

require 'json'

# Keep it simple. Focus on implementing just the requirements.
# Your application doesn't need to handle any other operations.

# Readability is key. Convey your intent with clear, organized code and with
# comments where appropriate.

# Don't worry about creating a UI, DB, server, or deployment.

module Main

  def self.run
    if ARGV.length < 1
      puts "Usage: process_playlist.rb changes.json"
      puts "changes.json format : "
      sample_changes_file = File.read("changes.json")
      sample_json = JSON.parse(sample_changes_file)
      puts JSON.pretty_generate sample_json
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
    @playlists = {}
    @songs = {}
  end

  # The changesfile should include multiple changes in a single file:
  # Add a new playlist; the playlist should contain at least one song.
  # Remove a playlist.
  # Add an existing song to an existing playlist.

  def process_changes(changes_file)
    puts "process_changes for #{changes_file}"
    changes_file = File.read("changes.json")
    changes_json = JSON.parse(changes_file)

    playlists = changes_json["playlists"]
    num_playlists_created = 0
    num_playlists_not_created = 0
    num_playlists_updated = 0
    num_playlists_not_updated = 0
    num_playlists_deleted = 0
    num_playlists_not_deleted = 0

    unless playlists.nil?
      create_lists = playlists["create"] || []
      create_lists.each do |create_hash|
        # we may want to capture playlists that were not created to debug what
        # went wrong
        if create_playlist(create_hash)
          num_playlists_created += 1
        else
          num_playlists_not_created += 1
        end
      end

      update_lists = playlists["update"] || []
      update_lists.each do |update_hsh|
        if update_playlist(update_hsh)
          num_playlists_updated += 1
        else
          num_playlists_not_updated += 1
        end
      end

      delete_lists = playlists["delete"] || []
      delete_lists.each do |id|
        if delete_playlist(id)
          num_playlists_deleted += 1
        else
          num_playlists_not_deleted += 1
        end
      end
    end

    puts "summary of changes applied :"
    puts "# of playlists created : #{num_playlists_created}"
    puts "# of playlists not created : #{num_playlists_not_created}"
    puts "# of playlists updated : #{num_playlists_updated}"
    puts "# of playlists not updated : #{num_playlists_not_updated}"
    puts "# of playlists deleted : #{num_playlists_deleted}"
    puts "# of playlists not deleted : #{num_playlists_not_deleted}"
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

    # TODO : validate JSON file schema for all input files

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

  def delete_playlist(id)
    play_list = find_play_list_by_id(id)
    unless play_list
      puts "could not find playlist with id #{id} to delete"
      return false
    end

    @playlists.delete(play_list.id)
  end

  def update_playlist(hsh)
    puts "update hash #{hsh}"
    play_list_id = hsh["id"]
    play_list = find_play_list_by_id(play_list_id)
    unless play_list
      puts "could not find playlist with id #{play_list_id} to update "
      return false
    end

    songs = find_songs_by_ids(hsh["song_ids"])
    if songs.empty?
      puts "no valid new songs were found to add to playlist : #{hsh["song_ids"]}"
      return false
    end

    play_list.songs.concat(songs)

    play_list
  end

  def create_playlist(hsh)

    play_list_id = hsh["id"]
    if find_play_list_by_id(play_list_id)
      puts "playlist with id #{play_list_id} already exists"
      return false
    end

    user = find_user_by_id(hsh["user_id"])
    unless user
      puts "could not find user with id #{hsh["user_id"]}"
      return false
    end

    songs = find_songs_by_ids(hsh["song_ids"])
    if songs.empty?
      puts "need at least 1 valid song to create a new playlist : #{hsh["song_ids"]}"
      return false
    end

    return PlayList.new(play_list_id, user, songs)
  end

  def find_play_list_by_id(id)
    @playlists[id]
  end

  def find_user_by_id(id)
    @users[id]
  end

  def find_songs_by_ids(ids)
    ids ||= []
    @songs.values_at(ids)
  end

  def find_song_by_id(id)
    @songs[id]
  end

end

Main.run
