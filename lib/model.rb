module Model
  User = Struct.new(:id, :name) do
    def to_hash
      { "id" => id, "name" => name }
    end
  end

  Song = Struct.new(:id, :artist, :title) do
    def to_hash
      { "id" => id, "artist" => artist, "title" => title }
    end
  end

  PlayList = Struct.new(:id, :user, :songs) do
    def to_hash
      song_ids = (songs || []).map { |song| song.id }
      hsh = { "id" => id}
      if user && user.id
        hsh["user_id"] = user.id
      end
      hsh["song_ids"] = song_ids

      hsh
    end
  end

end
