require_relative 'injest_mixtape'
require_relative 'play_list_update'
require_relative 'mix_tape_json_writer'
class MixTape

  include InjestMixtape
  include PlayListUpdate
  include MixTapeJsonWriter

  def initialize(data_file)
    @data_file = data_file

    @users = {}
    @playlists = {}
    @songs = {}
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


