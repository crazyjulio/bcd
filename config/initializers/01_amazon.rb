require "#{Rails.root}/lib/config/amazon_config.rb"

AmazonConfig.configure do |config|
  config.instruction_bucket = ENV['BCD_S3_INSTRUCTION_BUCKET']
  config.image_bucket = ENV['BCD_S3_IMAGE_BUCKET']
  config.asset_bucket = ENV['BCD_S3_ASSET_BUCKET']
  config.access_key = ENV['BCD_S3_KEY']
  config.secret = ENV['BCD_S3_SECRET']
end

Aws.config.update({
    region: 'us-east-1',
    credentials: Aws::Credentials.new(ENV['BCD_S3_KEY'], ENV['BCD_S3_SECRET'])
})