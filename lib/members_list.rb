# frozen_string_literal: true

require 'scraped'

class MembersList < Scraped::HTML
  field :members do
    noko.xpath('//div[@class="tab-content"]//table//tr[td]').map do |tr|
      MemberSection.new(response: response, noko: tr.css('td')).to_h
    end
  end
end
