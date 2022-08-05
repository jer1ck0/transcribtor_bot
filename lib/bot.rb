require 'telegram/bot'
require_relative 'modules/aws'
require_relative 'helpers/telegram_api_helper'

class Bot
  attr_accessor :related_cloud
  def initialize
    @related_cloud = AwsConnect.new
    Telegram::Bot::Client.run(ENV['tg_token']) do |bot|
      bot.listen do |message|
        bot_answer(message, bot)
      end
    end
  end

  private

  def bot_answer(message, bot)
    initiate_data_for message
    if @message.is_voice?
      @message.move_to_bucket related_cloud
      @message.transcribe bot, related_cloud
    else
      answer_about_wrong bot
    end
  end

  def initiate_data_for message
    @message = TelegramMessage.new(message)
    p @message
  end

  def answer_about_wrong bot
    p @message
    bot.api.send_message(chat_id: @message.chat, text: "I'm glad to help but I'm working only with voice message")
  end

end
