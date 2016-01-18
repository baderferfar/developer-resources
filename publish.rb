#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'logger'

require_relative('html_transformer')
require_relative('word_press_syncer')

logger = Logger.new(STDOUT)
syncer = WordPressSyncer.new(ENV['BLOG_HOSTNAME'], ENV['BLOG_USERNAME'], ENV['BLOG_PASSWORD'], logger: logger)

raise 'Usage: feed me html files' if ARGV.empty?

def get_value(name, lines)
  lines.find { |l| l.match("^#{name}:.*") }.to_s.split(/:/)[1].to_s.strip
end

ARGV.each do |html_file|
  lines = File.read(html_file).each_line.collect(&:strip).to_a  

  data = {}

  data[:post_name] = html_file.gsub(/deploy\/(.+)\.html$/,"\\1")
  optional_slug = get_value('slug', lines)
  data[:post_name] = optional_slug unless optional_slug.empty?

  %i(title level author email developer_section_name developer_section_slug).each do |key|
    data[key] = get_value(key, lines)
  end

  html = HtmlTransformer.transform(lines)

  # puts "data: #{data.inspect}"

  logger.info "publishing: #{data[:post_name]}"

  syncer.sync(data[:title], data[:post_name], html,
              [{key: 'developer_section_name', value: data[:developer_section_name]},
               {key: 'developer_section_slug', value: ''}]) # was developer_section_slug
end

