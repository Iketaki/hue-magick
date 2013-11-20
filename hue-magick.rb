#!/usr/bin/env ruby
require 'bundler'
Bundler.require

HUE_CHANGE_INTERVAL = 1.0 # [s]
GESTURE_INTERVAL = 2.0 # [s]

EM::run do
  # Linda cconnection
  url   = ENV["LINDA_BASE"]  || ARGV.shift || "http://linda.masuilab.org"
  space = ENV["LINDA_SPACE"] || "delta"

  puts "linda connecting... #{url}"
  linda = EM::RocketIO::Linda::Client.new url
  ts = linda.tuplespace[space]

  linda.io.on :connect do  ## RocketIO's "connect" event
    puts "linda connected #{url}"

    # Leap motion
    puts "leap motion connecting..."
    leap = LeapMotion.connect :gestures => true

    leap.on :connect do
      puts "leap motion connected"
    end

    ges_last = Time.now
    leap.on :gestures do |gestures|
      gestures.each do |g|
        now = Time.now
        if g.type == "swipe" && g.state == "stop" && now - ges_last > GESTURE_INTERVAL
          if g.direction[1] > 0 #up
            ts.write ["hue", "on"]
            puts "Up - hue:on #{now}"
          else
            ts.write ["hue", "off"]
            puts "Down - hue:off #{now}"
          end

          ges_last = now
        end
      end
    end

    hue = 0
    data_last = 0

    leap.on :data do |data|
      print "*"
      now = data.timestamp

      if data.hands.length >= 2 && now - data_last > HUE_CHANGE_INTERVAL * 1000 * 1000
        ts.write ["hue", 0, "hsb", hue, 255, 255]
        puts "Double Hands - hue:change_colors #{now}"

        data_last = now

        hue += 5000
        hue %= 65536
      end
    end

    leap.on :error do |err|
      STDERR.puts err
    end

   # leap.wait
  end
end
