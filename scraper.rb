#!/bin/env ruby
# encoding: utf-8

require 'date'
require 'combine_popolo_memberships'
require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'colorize'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'
require 'require_all'

require_rel 'lib'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
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
    end_date: Date.new(year, 11, 30).to_s,
  }
end

def scrape_list(url)
  noko = noko_for(url)
  noko.xpath('//div[@class="tab-content"]//table//tr[td]').map do |tr|
    tds = tr.css('td')
    MemberSection.new(response: Scraped::Request.new(url: url).response, noko: tds).to_h
  end
end

memberships_from_page = scrape_list('http://www.senado.gov.ar/senadores/listados/listaSenadoRes')

data = CombinePopoloMemberships.combine(
  id: memberships_from_page,
  term: terms,
)

ScraperWiki.save_sqlite([:id, :term], data)
