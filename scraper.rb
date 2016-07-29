#!/bin/env ruby
# encoding: utf-8

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

def scrape_list(url)
  noko = noko_for(url)
  noko.xpath('//div[@class="tab-content"]//table//tr[td]').each do |tr|
    tds = tr.css('td')
    person_url = URI.join(url, tds[0].css('a/@href').text).to_s
    family_name, given_name = tds[1].css('a').text.split("\n").map { |n| n.sub(',','').tidy }.reject(&:empty?)
    start_date, end_date = tds[4].text.split("\n").map(&:tidy).map { |d| d.split("/").reverse.join("-") }

    data = { 
      id: person_url.split('/').last,
      image: tds[0].css('a img/@src').text,
      name: "#{given_name} #{family_name}",
      sort_name: "#{family_name}, #{given_name}",
      given_name: given_name,
      family_name: family_name,
      district: tds[2].text.tidy,
      party: tds[3].text.tidy,
      start_date: start_date,
      end_date: end_date,
      email: tds[5].css('a[href*="mailto:"]/@href').text.sub('mailto:','').tidy,
      phone: tds[5].xpath('.//i[@class="icon-bell"]//following-sibling::text()[contains(.,"+54")]').text.tidy,
      facebook: tds[5].css('a[href*="facebook"]/@href').text.tidy,
      twitter: tds[5].css('a[href*="twitter"]/@href').text.tidy,
      # 6 year terms, so we should split these all into three, but for
      # now just take the latest one
      term: 2015,
      source: person_url,
    }
    # }.merge(scrape_person(person_url))
    data[:image] = URI.join(url, data[:image]).to_s unless data[:image].to_s.empty?
    ScraperWiki.save_sqlite([:id, :term], data)
  end
end

scrape_list('http://www.senado.gov.ar/senadores/listados/listaSenadoRes')
