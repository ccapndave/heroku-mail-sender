include Recaptcha::Adapters::ControllerMethods
include Recaptcha::Adapters::ViewMethods

before do
  content_type :json
  headers "Access-Control-Allow-Origin" => "*",
          "Access-Control-Allow-Methods" => ["POST"]
end

set :protection, false

# Given a set of parameters, send an email using Mailgun.
#
# to - the email address to send the message to (encrypted)
# site - the site the contact form is hosted at (encrypted)
# from - the email address of the sender
# subject - the subject of the message
# body - the message
post "/send_email" do
  begin
    encryption_key = Base64.urlsafe_decode64(ENV["ENCRYPTION_KEY"])
    to = Base64.urlsafe_decode64(params[:to]).decrypt(encryption_key)
    site = Base64.urlsafe_decode64(params[:site]).decrypt(encryption_key)
  rescue 
    { :success => false, :reason => "decryption" }.to_json
  else
    if verify_recaptcha
      res = Pony.mail(
        :from => "#{params[:name]}<#{params[:email]}>",
        :to => to,
        :subject => "[#{site}] #{params[:subject]}",
        :body => params[:message],
        :via => :smtp,
        :via_options => {
          :address              => ENV["MAILGUN_SMTP_SERVER"],
          :port                 => ENV["MAILGUN_SMTP_PORT"],
          :enable_starttls_auto => true,
          :user_name            => ENV["MAILGUN_SMTP_LOGIN"],
          :password             => ENV["MAILGUN_SMTP_PASSWORD"],
          :authentication       => :plain,
          :domain               => "heroku.com"
        })
      content_type :json
      if res
        { :success => true }.to_json
      else
        { :success => false, :reason => "email" }.to_json
      end
    else
      { :success => false, :reason => "recaptcha" }.to_json
    end
  end
end

# These routes are only available in development
if ENV["RACK_ENV"] == "development"
  # Generate a new encryption key
  get "/keygen" do
    keygen = OpenSSL::Cipher::AES.new(128, :CBC).encrypt
    Base64.urlsafe_encode64(keygen.random_key)
  end

  # Encrypt the `value` parameter using the configured encryption key
  get "/encrypt" do
    encryption_key = Base64.urlsafe_decode64(ENV["ENCRYPTION_KEY"])
    ciphertext = params[:value].encrypt(encryption_key)
    Base64.urlsafe_encode64(ciphertext)
  end

  # Output the expected reCaptcha client side code for inclusion in some other site
  get "/tags" do
    <<-HTML
      <form action="">
        #{recaptcha_tags}
        <input type="submit"/>
      </form>
    HTML
  end
end

get "/*" do
  raise Sinatra::NotFound
end

not_found do 
  "Not found"
end
