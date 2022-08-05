require 'telegram/bot'
require 'httparty'
require 'json'
require 'ostruct'

class TelegramMessage
  attr_accessor :chat, :local_name
  def initialize tg_message
    @chat = tg_message.chat.id
    @type = tg_message.voice.nil? ? 'other' : 'voice'
    @file_id = tg_message.voice.file_id if @type == 'voice'
    @local_name = "tmp/voice_#{@file_id}.ogg"
    save_voice_message_if_possible
  end

  def is_voice?
    @type == 'voice'
  end

  def save_voice_message_if_possible
    if is_voice?
      response = HTTParty.get("https://api.telegram.org/bot#{ENV['tg_token']}/getFile?file_id=#{@file_id}")
      path = ::JSON.parse(response.body, object_class: OpenStruct).result.file_path
      file_content = HTTParty.get("https://api.telegram.org/file/bot#{ENV['tg_token']}/#{path}").body
      File.open(@local_name, 'wb') { |fp| fp.write(file_content) }
      @voice_message = File.open(@local_name, 'rb')
    end
  end
  
  def move_to_bucket aws_instance
    aws_instance.send_to_bucket(@voice_message, @local_name, 'transcribtor')
  end

  def transcribe bot, ya_cloud
    options = {
      headers: {"Authorization" => "Api-Key #{ENV['yandex_api_key']}"},
      body: {
        "config" => {
          "specification" => {
            "languageCode" => "ru-RU"
                    }
            },
            "audio" => {
              "uri" => ya_cloud.link_to_file_in_bucket('transcribtor', local_name)
                       }
            }.to_json
              }

    response = HTTParty.post('https://transcribe.api.cloud.yandex.net/speech/stt/v2/longRunningRecognize', options)
    loop do
      ready = HTTParty.get("https://operation.api.cloud.yandex.net/operations/#{response['id']}", options)
      sleep 4
      if ready['done'] == true
          if ready['response']['chunks'] 
            result = ready['response']['chunks'].map { |alt| alt['alternatives'][0]['text']}.join('. ')
            bot.api.send_message(chat_id: chat, text: result)
          else
            bot.api.send_message(chat_id: chat, text: "Something went wrong. Try again")
          end
          break
      end
    end        
  end
end