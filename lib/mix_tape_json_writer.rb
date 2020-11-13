require 'json'
module MixTapeJsonWriter
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
end
