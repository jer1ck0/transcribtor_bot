class AwsConnect
  require 'aws-sdk-s3'
  require 'dotenv'

  Dotenv.load
  Aws.config.update(
      region: 'ru-central1',
      credentials: Aws::Credentials.new(ENV["yandex_key_id"], ENV["yandex_secret_key"])
    )

  attr_accessor :client, :signer
  def initialize
    @client = Aws::S3::Client.new(endpoint: "https://storage.yandexcloud.net")
    @signer = Aws::S3::Presigner.new(client: @client)
  end

  def send_to_bucket(file, file_name, bucket_name)
    client.put_object(
      bucket: bucket_name,
      key: file_name,
      body: file
  )
  end

  def link_to_file_in_bucket(bucket_name, file_name)
    signer.presigned_url(:get_object, bucket: bucket_name, key: file_name)
  end
end