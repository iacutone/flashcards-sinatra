require 'aws-sdk'

class S3Coordinator
  attr_reader :bucket

  def initialize
    @s3 = AWS::S3.new(
      :access_key_id     => ENV['AWSAccessKeyId'],
      :secret_access_key => ENV['AWSSecretKey']
    )
    @bucket = @s3.buckets[ENV['AWSBucket']]
  end

  def upload_image(file, file_name)
    bucket.objects[file_name].write(:file => file)
  end

  def fetch_image_url(file_name)
    object = bucket.objects[file_name]
    object.url_for(:read).to_s
  end
end
