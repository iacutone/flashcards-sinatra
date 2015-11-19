require 'sinatra'
require 'sinatra/activerecord'
require './user'
require './image'
require './s3_coordinator'
require './environments'

post 'sign_up' do

  if request.post?
    if params && params[:email] && params[:password]

      encrypted_password = params['password'].gsub(" ","+").concat("\n")
      decrypted_password = AESCrypt.decrypt(encrypted_password, ENV['AuthPassword'])
      
      user = User.new(email: params[:email], password: decrypted_password, password_confirmation: decrypted_password)

      if user.save
        render(
                status: 200,
                json: {
                  success: true,
                  data: {
                    id: user.id,
                    email: user.email
                  }
                    
                }
              ) and return
      else
        render(
                status: 400,
                json: {
                  success: false,
                  info: user.errors.full_messages.first
                }
              ) and return
      end
    end
  end
end

post 'sign_in' do
  
  if request.post?
    if params[:email].present? && params[:password].present? 

      user = User.find_by(email: params[:email])

      if user.present?
        encrypted_password = params['password'].gsub(" ","+").concat("\n")
        decrypted_password = AESCrypt.decrypt(encrypted_password, ENV['AuthPassword'])

        if user.authenticate(decrypted_password) == user  
          render :json => user.to_json, :status => 200
        else
          render(
                status: 400,
                json: {
                  success: false,
                  info: "Incorrect password"
                }
              ) and return
        end      
      else
        render(
                status: 400,
                json: {
                  success: false,
                  info: "User not found"
                }
              ) and return
      end
    end
  end
end

post 'data' do
  s3        = S3Coordinator.new
  user      = User.find_by(email: params[:email])
  file_name = "#{user.email} #{Time.now.to_s(:number)}.jpg"
  image     = MiniMagick::Image.new(params['photo'].tempfile.path)
  image.resize "375x375"
  s3_image  = s3.upload_image(image.path, file_name)

  image = Image.new(user_id: user.id, word: params[:image_name], file_name: file_name)

  if image.save
    render(status: 200)
  else
    render(
          status: 200,
          json: {
            success: false,
            info: "You have not uploaded and images."
          }
        ) and return
  end
end

get 'select_image' do
  user        = User.find_by(email: params[:email])
  user_count  = user.counter
  image_count = user.images.not_hidden.size
  increment   = params[:increment].to_i

  if user_count + increment >= image_count
    user.counter = 0
    user.save!
  elsif user_count + increment < 0
    user.counter = image_count - 1
    user.save!
  else
    user.counter = user_count + increment
    user.save!
  end

  image = user.images[user.counter]
  
  s3 = S3Coordinator.new

  if user.present? && user.images.present?
    render(
            status: 200,
            json: {
              success: true,
              data: {
                s3_url: s3.fetch_image_url(image.file_name),
                word: image.word
              }
            }
          ) and return
  else
    render(
          status: 400,
          json: {
            success: false,
            info: "You have not uploaded and images."
          }
        ) and return
  end
end

get 'images' do
  user = User.find_by(email: params[:email])

  if user.present? && user.images.present?
    render(
            status: 200,
            json: {
              success: true,
              data: {
                images: user.images.not_hidden
              }
            }
          ) and return
  else
    render(
          status: 400,
          json: {
            success: false,
            info: "You have not uploaded and images."
          }
        ) and return
  end
end

post 'edit_image' do
  image = Image.find(params[:image_id])
  image.word = params[:word]
  
  if image.save
    render(
            status: 200,
            json: {
              success: true
            }
          ) and return
  else
    render(
          status: 200,
          json: {
            success: false,
            info: image.errors.first
          }
        ) and return
  end
end

post 'hide_image' do
  user  = User.find_by(email: params[:email])
  image = Image.find(params[:image_id])
  image.hidden = true
  
  if image.save
    render(
            status: 200,
            json: {
              success: true,
              data: {
                images: user.images.not_hidden
              }
            }
          ) and return
  else
    render(
          status: 200,
          json: {
            success: false,
            info: image.errors.first
          }
        ) and return
  end
end
