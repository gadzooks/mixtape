require 'json'
require_relative 'model'
module PlayListUpdate
  include Model

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

end
