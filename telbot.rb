require 'telegram/bot'
require 'logger'
require_relative 'lib/sender'

TOKEN = '632124239:AAFZFLH6Vl7sDMqxji_NLtmJsziaS9Ry4no'

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
