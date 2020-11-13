#!/usr/bin/env ruby

require 'json'
require_relative 'lib/mix_tape'

# to run : ./process_playlist.rb data/changes.json
# for usage : ./process_playlist.rb
# Tested on Macbook with ruby 2.5.3

# NOTE : Assumptions :
# 1. all json files are valid. I would add a json schema validator before
#    processing the file
# 2. There are no tests. I would use Rspec to add tests.

# Should be set via ENV
DATA_DIR = 'data'

module Main

  def self.run
    if ARGV.length < 1
      puts "Usage: process_playlist.rb changes.json"
      puts "changes.json format : "
      sample_changes_file = File.read("#{DATA_DIR}/changes.json")
      sample_json = JSON.parse(sample_changes_file)
      puts JSON.pretty_generate sample_json
      exit -1
    end

    mix_tape = MixTape.new("#{DATA_DIR}/mixtape-data.json")

    mix_tape.injest_mixtape_data

    changes_file = ARGV[0]

    mix_tape.process_changes(changes_file)
    mix_tape.print_updated_state
  end

end

Main.run
