#!/usr/bin/env ruby
# encoding: utf-8

require_relative "bundle/bundler/setup"
require "alfred"
require 'json'
require 'faraday'
require 'pp'
require 'open-uri'

def search_niconico_videos(search_word, client)
  body = { query: search_word,
           service: ["video"],
           search: ["title", "description", "tags"],
           join: ["cmsid", "title", "view_counter", "comment_counter", "mylist_counter", "start_time", "thumbnail_url"],
           sort_by: "view_counter",
           issuer: "testApp"
         }

  request = client.post do |req|
    req.url '/api/snapshot/'
    req.headers['Content-Type'] = 'application/json'
    req.body = JSON.generate(body)
  end

  return [] if JSON.parse(request.body.split("\n")[-3])["values"][0]["total"] == 0

  search_results = JSON.parse(request.body.split("\n")[0])["values"]
  return search_results
end


client = Faraday.new(url: 'http://api.search.nicovideo.jp')

Alfred.with_friendly_error do |alfred|
  fb = alfred.feedback

  if ARGV.length == 0
    puts fb.to_xml
    break
  end

  search_word = ARGV.join(" ").encode("UTF-8-MAC", "UTF-8").strip
  search_results = search_niconico_videos(search_word, client)
  search_results.each_with_index do |video, i|
    filename = "icon_#{i}"
    open(filename, 'w') do |output|
      open(video["thumbnail_url"]) do |data|
        output.write(data.read)
      end
    end
    fb.add_item({
      uid:      "",
      title:    video["title"],
      icon:     {name: filename},
      subtitle: "投稿:#{video["start_time"]} 再生:#{video["view_counter"]} コメント:#{video["comment_counter"]} マイリスト:#{video["mylist_counter"]}",
      arg:      "http://www.nicovideo.jp/watch/#{video["cmsid"]}",
      valid:    "yes"
    })
  end
  puts fb.to_xml
end
