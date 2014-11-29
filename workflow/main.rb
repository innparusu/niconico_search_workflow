#!/usr/bin/env ruby
# encoding: utf-8

require_relative "bundle/bundler/setup"
require "alfred"
require 'json'
require 'faraday'
require 'pp'

def search_niconico_videos(search_word, client)
  body = { query: search_word,
           service: ["video"],
           search: ["title", "description", "tags"],
           join: ["cmsid", "title", "view_counter", "comment_counter", "mylist_counter"],
           sort_by: "view_counter",
           issuer: "testApp"
  }

  request = client.post do |req|
    req.url '/api/snapshot/'
    req.headers['Content-Type'] = 'application/json'
    req.body = JSON.generate(body)
  end

  return nil if JSON.parse(request.body.split("\n")[-3])["values"][0]["total"] == 0

  results = JSON.parse(request.body.split("\n")[0])["values"]
  return results
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

  if search_results.nil?
    puts fb.to_xml
    break
  end

  search_results.each do |video|
    fb.add_item({
      uid:      "",
      title:    video["title"],
      subtitle: "再生:#{video["view_counter"]} コメント:#{video["comment_counter"]} マイリスト:#{video["mylist_counter"]}",
      arg:      "http://www.nicovideo.jp/watch/#{video["cmsid"]}",
      valid:    "yes"
    })
  end

  puts fb.to_xml
end
