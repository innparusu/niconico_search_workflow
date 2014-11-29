#!/usr/bin/env ruby
# encoding: utf-8

require_relative "bundle/bundler/setup"
require "alfred"
require 'json'
require 'faraday'

def search_niconico_videos(search_word, client)
  body = { query: search_word,
           service: ["video"],
           search: ["title", "description", "tags"],
           join: ["cmsid", "title", "thumbnail_url"],
           sort_by: "view_counter",
           issuer: "testApp"
  }

  request = client.post do |req|
    req.url '/api/snapshot/'
    req.headers['Content-Type'] = 'application/json'
    req.body = JSON.generate(body)
  end

  return JSON.parse(request.body.split("\n")[0])["values"]
end


client = Faraday.new(url: 'http://api.search.nicovideo.jp')

Alfred.with_friendly_error do |alfred|
  fb = alfred.feedback

  if ARGV.length > 0
    search_word = ARGV.join(" ").encode("UTF-8-MAC", "UTF-8").strip
    search_niconico_videos(search_word, client).each do |video|
      fb.add_item({
        uid:      "",
        title:    video["title"],
        subtitle: "http://www.nicovideo.jp/watch/#{video["cmsid"]}",
        arg:      "http://www.nicovideo.jp/watch/#{video["cmsid"]}",
        valid:    "yes",
      })
    end
  else
  end
  puts fb.to_xml
end
