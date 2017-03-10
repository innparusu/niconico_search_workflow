#!/usr/bin/env ruby
# encoding: utf-8
require_relative 'bundle/bundler/setup'
require 'alfred'
require 'json'
require 'faraday'
require 'pp'
require 'open-uri'

def search_niconico_videos(search_word, client)
  params = { 
    q: search_word,
    targets: 'title,description,tags',
    fields: 'contentId,title,viewCounter,commentCounter,mylistCounter,startTime',
    _sort: '-viewCounter',
    _context: 'testApp'
  }
  request = client.post do |req|
    req.url 'api/v2/snapshot/video/contents/search'
    req.headers['User-Agent'] = 'testApp'
    req.params = params
  end

  res = JSON.parse(request.body)
  return res['data'].length == 0 ? [] : res['data']
end


client = Faraday.new(url: 'http://api.search.nicovideo.jp')

Alfred.with_friendly_error do |alfred|
  fb = alfred.feedback

  if ARGV.length == 0
    puts fb.to_xml
    break
  end

  search_word = ARGV.join(" ").encode('UTF-8-MAC', 'UTF-8').strip
  search_results = search_niconico_videos(search_word, client)
  search_results.each do |video|
    fb.add_item({
      uid:      "",
      title:    video['title'],
      subtitle: "投稿:#{video['startTime']} 再生:#{video['viewCounter']} コメント:#{video['commentCounter']} マイリスト:#{video['mylistCounter']}",
      arg:      "http://www.nicovideo.jp/watch/#{video['contentId']}",
      valid:    "yes"
    })
  end
  puts fb.to_xml
end
