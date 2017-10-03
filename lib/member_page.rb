# frozen_string_literal: true

require 'scraped'

class MemberPage < Scraped::HTML
  field :name do
    "#{given_name} #{family_name}"
  end

  field :given_name do
    member_info.at_xpath('./text()').text.tidy
  end

  field :family_name do
    member_info.at_xpath('./span').text.tidy
  end

  private

  def member_info
    noko.at_xpath('//div[@class="col-sm-12 col-md-5"]/div')
  end
end
