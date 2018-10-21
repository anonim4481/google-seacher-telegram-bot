# frozen_string_literal: true

require 'telegram/bot'
require_relative 'google_seacher'

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
      kb = Telegram::Bot::Types::ReplyKeyboardRemove
             .new(remove_keyboard: true)
      @bot.api.sendMessage(chat_id: message.chat.id, 
                           text: 'Enter request', reply_markup: kb)
    else
      @bot.api.sendMessage(chat_id: message.chat.id, 
                           text: 'Enter request', reply_markup: kb)
    end
  end

  def more(message)
    if @seacher
      @bot.api.sendMessage(chat_id: message.chat.id, 
                           text: @seacher.next)
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
      kb = Telegram::Bot::Types::ReplyKeyboardMarkup
             .new(keyboard: %w[/more /stop], one_time_keyboard: true)
      @bot.api.sendMessage(chat_id: message.chat.id, 
                           text: @seacher.next, reply_markup: kb)
    end
  end

  def alert(message, text)
    @bot.api.sendMessage(chat_id: message.chat.id, text: text)
  end
end
