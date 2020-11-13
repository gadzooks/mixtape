require_relative 'injest_mixtape'
class MixTape

  include InjestMixtape

  def initialize(data_file)
    # TODO check if file is valid ??
    @data_file = data_file

    @users = {}
    @playlists = {}
    @songs = {}
  end

  # The changesfile should include multiple changes in a single file:
  # Add a new playlist; the playlist should contain at least one song.
  # Remove a playlist.
  # Add an existing song to an existing playlist.

  def process_changes(file_name)
    puts
    puts "processing changes for #{file_name}"
    changes_file = File.read(file_name)
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

    puts
    puts "summary of changes applied :"
    puts "# of playlists created : #{num_playlists_created}"
    puts "# of playlists updated : #{num_playlists_updated}"
    puts "# of playlists deleted : #{num_playlists_deleted}"

    puts "# of playlists NOT created : #{num_playlists_not_created}" if num_playlists_not_created > 0
    puts "# of playlists NOT updated : #{num_playlists_not_updated}" if num_playlists_not_updated > 0
    puts "# of playlists NOT deleted : #{num_playlists_not_deleted}" if num_playlists_not_deleted > 0
  end

  def print_updated_state
    output = {
      "users" => @users.values.map { |u| { "id" => u.id, "name" => u.name  } } ,
      "playlists" => @playlists.values.map { |p| p.to_hash },
      "songs" => @songs.values.map {|s| s.to_hash },
    }

    updated_file = "#{DATA_DIR}/output.json"
    puts "\nsaving results to #{updated_file}"
    File.open(updated_file, "w") do |f|
      f.write(JSON.pretty_generate(output))
    end
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
    play_list_id = hsh["id"]
    play_list = find_play_list_by_id(play_list_id)
    unless play_list
      puts "could not find playlist with id #{play_list_id} for updating"
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

    songs = find_songs_by_ids(hsh["song_ids"]).compact
    if songs.empty?
      puts "need at least 1 valid song to create a new playlist : #{hsh["song_ids"]}"
      return false
    end

    play_list = PlayList.new(play_list_id, user, songs)
    @playlists[play_list_id] = play_list
    play_list
  end

  def find_play_list_by_id(id)
    @playlists[id]
  end

  def find_user_by_id(id)
    @users[id]
  end

  def find_songs_by_ids(ids)
    ids ||= []
    @songs.values_at(*ids)
  end

  def find_song_by_id(id)
    @songs[id]
  end

end


