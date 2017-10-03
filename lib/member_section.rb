require 'scraped'

class MemberSection < Scraped::HTML
  field :id do
    person_url.split('/').last
  end

  field :image do
    URI.join(url, person_image).to_s unless person_image.to_s.empty?
  end

  field :sort_name do
    noko[1].css('a')
           .text
           .split("\n")
           .map { |n| n.sub(',', '').tidy }
           .reject(&:empty?).first
  end

  field :district do
    noko[2].text.tidy
  end

  field :party do
    noko[3].text.tidy
  end

  field :start_date do
    dates.first
  end

  field :end_date do
    dates.last
  end

  field :mandate_start do
    start_date
  end

  field :mandate_end do
    end_date
  end

  field :email do
    noko[5].css('a[href*="mailto:"]/@href').text.sub('mailto:','').tidy
  end

  field :phone do
    noko[5].xpath('.//i[@class="icon-bell"]//following-sibling::text()[contains(.,"+54")]')
           .text
           .tidy
  end

  field :facebook do
    noko[5].css('a[href*="facebook"]/@href').text.tidy
  end

  field :twitter do
    noko[5].css('a[href*="twitter"]/@href').text.tidy
  end

  field :source do
    person_url
  end

  private

  def person_url
    URI.join(url, noko[0].css('a/@href').text).to_s
  end

  def person_image
    noko[0].css('a img/@src').text
  end

  def dates
    noko[4].text.split("\n").map(&:tidy).map do |d|
      d.split('/').reverse.join('-')
    end
  end
end
