require 'sinatra'
require 'evernote_oauth'
enable :sessions

# Load our dependencies and configuration settings
$LOAD_PATH.push(File.expand_path(File.dirname(__FILE__)))
require "evernote_config.rb"

before do
  if OAUTH_CONSUMER_KEY.empty? || OAUTH_CONSUMER_SECRET.empty?
    halt '<span style="color:red">Before using this sample code you must edit evernote_config.rb and replace OAUTH_CONSUMER_KEY and OAUTH_CONSUMER_SECRET with the values that you received from Evernote. If you do not have an API key, you can request one from <a href="http://dev.evernote.com/documentation/cloud/">dev.evernote.com/documentation/cloud/</a>.</span>'
  end
end


  def auth_token
    session[:access_token].token if session[:access_token]
  end

   def client
    @client ||= EvernoteOAuth::Client.new(token: auth_token, consumer_key:OAUTH_CONSUMER_KEY, consumer_secret:OAUTH_CONSUMER_SECRET, sandbox: SANDBOX)
  end

  def user_store
    @user_store ||= client.user_store
  end

  def note_store
    @note_store ||= client.note_store
  end

   def en_user
    user_store.getUser(auth_token)
  end

  def notebooks
    @notebooks ||= note_store.listNotebooks(auth_token)
  end

  def total_note_count
    filter = Evernote::EDAM::NoteStore::NoteFilter.new
    counts = note_store.findNoteCounts(auth_token, filter, false)
    notebooks.inject(0) do |total_count, notebook|
      total_count + (counts.notebookCounts[notebook.guid] || 0)
    end
  end