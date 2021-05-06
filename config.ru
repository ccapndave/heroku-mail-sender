require "dotenv/load"
require "rubygems"
require "sinatra"
require "json"
require "recaptcha"
require "pony"
require "openssl"
require "base64"

Recaptcha.configure do |config|
  config.site_key  = ENV["RECAPTCHA_SITE_KEY"]
  config.secret_key = ENV["RECAPTCHA_SECRET_KEY"]
end

class String
  def encrypt(key)
    cipher = OpenSSL::Cipher::AES.new(128, :CBC).encrypt
    cipher.key = key
    cipher.update(self) + cipher.final
  end

  def decrypt(key)
    cipher = OpenSSL::Cipher::AES.new(128, :CBC).decrypt
    cipher.key = key
    cipher.update(self) + cipher.final
  end
end

require "./application"
run Sinatra::Application