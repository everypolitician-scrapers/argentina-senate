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
    person_url = URI.join(url, tds[0].css('a/@href').text).to_s
    start_date, end_date = tds[4].text.split("\n").map(&:tidy).map { |d| d.split("/").reverse.join("-") }
    data = { 
      id: person_url.split('/').last,
      image: tds[0].css('a img/@src').text,
      sort_name: tds[1].css('a')
                       .text
                       .split("\n")
                       .map { |n| n.sub(',','').tidy }
                       .reject(&:empty?).first,
      district: tds[2].text.tidy,
      party: tds[3].text.tidy,
      start_date: start_date,
      end_date: end_date,
      email: tds[5].css('a[href*="mailto:"]/@href').text.sub('mailto:','').tidy,
      phone: tds[5].xpath('.//i[@class="icon-bell"]//following-sibling::text()[contains(.,"+54")]').text.tidy,
      facebook: tds[5].css('a[href*="facebook"]/@href').text.tidy,
      twitter: tds[5].css('a[href*="twitter"]/@href').text.tidy,
      source: person_url,
    }
    # }.merge(scrape_person(person_url))
    data[:image] = URI.join(url, data[:image]).to_s unless data[:image].to_s.empty?
    data
  end
end

memberships_from_page = scrape_list('http://www.senado.gov.ar/senadores/listados/listaSenadoRes')

data = CombinePopoloMemberships.combine(
  id: memberships_from_page,
  term: terms,
)

ScraperWiki.save_sqlite([:id, :term], data)
