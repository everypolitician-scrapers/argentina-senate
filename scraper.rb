#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'combine_popolo_memberships'
require 'date'
require 'nokogiri'
require 'open-uri'
require 'pry'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

require 'require_all'
require_rel 'lib'

class String
  def tidy
    gsub(/[[:space:]]+/, ' ').strip
  end
end

def scraper(pair)
  url, klass = pair.to_a.first
  warn url
  klass.new(response: Scraped::Request.new(url: url).response)
end

# The terms of senators are 6 years long, but offset by two or four
# years from their colleagues, so we're assuming that each year is a
# different term. Each session runs from the 1st of March to the 30th
# of November each year, [1] so treat those as the start and end dates
# of each "term".
# [1] https://en.wikipedia.org/wiki/National_Congress_of_Argentina
terms = (2015..Date.today.year).map do |year|
  {
    id: year,
    start_date: Date.new(year, 3, 1).to_s,
    end_date: Date.new(year, 11, 30).to_s
  }
end

url = 'http://www.senado.gov.ar/senadores/listados/listaSenadoRes'
memberships = scraper(url => MembersList).members.map(&:to_h).map do |member|
  member.merge(scraper(member[:source] => MemberPage).to_h)
end

data = CombinePopoloMemberships.combine(
  id: memberships,
  term: terms
)
data.each { |mem| puts mem.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h } if ENV['MORPH_DEBUG']

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
ScraperWiki.save_sqlite(%i[id term], data)
