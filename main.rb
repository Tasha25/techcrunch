require 'bundler/setup'
require 'rubygems'
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/flash'
require 'sinatra/reloader' if development?
# require './config/environments'
require 'pathname'
require 'uri'
require 'open-uri'
require 'carrierwave'
require 'carrierwave/orm/activerecord'
require 'mini_magick'
require 'bcrypt'

require_relative 'en_oauth'

require './routes/init'
require  './helpers/init'
require  './models/init'


  get '/' do
    erb :"index.html"
  end

  get '/reset' do
  session.clear
  redirect '/'
end

get '/list' do
  begin
    # Get notebooks
    session[:notebooks] = notebooks.map(&:name)
    # Get username
    session[:username] = en_user.username
    # Get total note count
    session[:total_notes] = total_note_count
    erb :"index.html"
  rescue => e
    @last_error = "Error listing notebooks: #{e.message}"
    erb :"error.html"
  end
end

get '/requesttoken' do
  callback_url = request.url.chomp("requesttoken").concat("callback")
  begin
    session[:request_token] = client.request_token(:oauth_callback => callback_url)
    redirect '/authorize'
  rescue => e
    @last_error = "Error obtaining temporary credentials: #{e.message}"
    erb :"error.html"
  end
end

get '/authorize' do
  if session[:request_token]
    redirect session[:request_token].authorize_url
  else
    # You shouldn't be invoking this if you don't have a request token
    @last_error = "Request token not set."
    erb :"error.html"
  end
end

get '/callback' do
  unless params['oauth_verifier'] || session['request_token']
    @last_error = "Content owner did not authorize the temporary credentials"
    halt erb :error
  end
  session[:oauth_verifier] = params['oauth_verifier']
  begin
    session[:access_token] = session[:request_token].get_access_token(:oauth_verifier => session[:oauth_verifier])
    redirect '/list'
  rescue => e
    @last_error = 'Error extracting access token'
    erb :"error.html"
  end
end



