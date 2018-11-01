# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'open-uri'
require 'nokogiri'
require 'cgi'

class GoogleSeacher
  BASE_URL = 'https://www.google.ru/search'

  def initialize(search_str)
    @search_str = search_str
    @results = []
    @current = 0
  end

  def next
    link = pull_href_from_results
    @current += 1
    if link.start_with?('/search?')
      self.next
    elsif link.start_with?('/url?')
      values = link[5..-1].split('&').map { |e| e.split('=')[1] }
      CGI.unescape(values.find { |e| e.start_with?('http') })
    else
      "unrecognize: #{link}"
    end
  end

  private

  def pull_href_from_results
    next_page if @results.size - 1 <= @current % 10
    @results[@current % 10][:href]
  end

  def next_page
    html = request
    raise unless html
    doc = Nokogiri::HTML(html)
    raise if doc.css('.r').empty?
    @results.clear
    @current = ceil_to_decade(@current)
    doc.css('.r').each do |e|
      a = e.css('a')
      @results << { name: a.text, href: a.attr('href').value }
    end
  end

  def ceil_to_decade(num)
    (num.to_f / 10).ceil * 10
  end

  def request
    url = URI(BASE_URL)
    params = { q: @search_str, start: @current }
    url.query = URI.encode_www_form(params)
    req = Net::HTTP::Get.new(url.to_s)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    res = http.start { |htp| htp.request(req) }
    res.body if res.is_a?(Net::HTTPSuccess)
  end
end
