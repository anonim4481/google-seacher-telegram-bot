require 'net/http'
require 'uri'
require 'open-uri'
require 'nokogiri'
require 'telegram/bot'
require 'logger'

TOKEN = '632124239:AAFZFLH6Vl7sDMqxji_NLtmJsziaS9Ry4no'

class GoogleSeacher
  BASE_URL = 'https://www.google.ru/search'.freeze

  def initialize(search_str)
    @search_str = search_str
    @results = []
    @current = 0
  end

  def next
    next_page if @results.size <= @current
    link = @results[@current % 10][:href]
    @current += 1
    if link.start_with?('/search?')
      self.next
    else
      link.start_with?('/url?') ? link[7..-1] : "unrecognize" 
    end
  end

  private

  def next_page
    html = request
    raise unless html
    doc = Nokogiri::HTML(html)
    raise if doc.css('.r').empty?
    @results.clear
    doc.css('.r').each do |e|
      a = e.css('a')
      @results << { name: a.text, href: a.attr('href').value }
    end
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

class Sender
  def initialize(bot)
    @bot = bot
    @seacher = nil
  end

  def start(message)
    @bot.api.sendMessage(chat_id: message.chat.id,
                         text: "Hello, #{message.from.first_name}")
  end

  def stop(message)
    if @seacher
      @seacher = nil
    else
      @bot.api.sendMessage(chat_id: message.chat.id, 
                           text: 'Enter request')
    end
  end

  def more(message)
    if @seacher
      @bot.api.sendMessage(chat_id: message.chat.id, 
                           text: @seacher.next[:href])
    else
      @bot.api.sendMessage(chat_id: message.chat.id, 
                           text: 'Enter request')
    end
  end

  def request(message)
    if @seacher
      @bot.api.sendMessage(chat_id: message.chat.id, 
                           text: 'Enter /more or /stop')
    else
      @seacher = GoogleSeacher.new(message.text)
      @bot.api.sendMessage(chat_id: message.chat.id, 
                           text: @seacher.next[:href])
    end
  end
end

logger = Logger.new(STDOUT)

Telegram::Bot::Client.run(TOKEN) do |bot|
  sender = Sender.new(bot)
  logger.debug "bot cycle"
  bot.listen do |message|
    logger.debug "get message: #{message.inspect}"
    case message.text
    when '/start'
      logger.debug "message start"
      sender.start(message)
    when '/stop'
      logger.debug "message stop"
      sender.stop(message)
    when '/more'
      logger.debug "message more"
      sender.more(message)
    else
      logger.debug "message else"
      sender.request(message)
    end
  end
end
