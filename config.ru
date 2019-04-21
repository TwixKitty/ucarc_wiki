require 'rubygems'
require 'gollum/app'
require 'digest'

gollum_path = File.expand_path(File.dirname(__FILE__))
wiki_options = {
    :live_preview => false,
    :allow_editing => true,
    :universal_toc => false
}

users = {'ryan' => '312433c28349f63c4f387953ff337046e794bea0f9b9ebfcb08e90046ded9c76',
         'patrick' => '0b14d501a594442a01c6859541bcb3e8164d183d32937b851835442f69d5c94e',
         'brandon' => 'e9c940cd70579038143a03e5b94cccb0a037be5b226eaa2449655c5c0691241c'
         }

# Ryan Coding starts here
class SelectiveAuth < Rack::Auth::Basic
  # a regular expression that determines which paths will write
  WRITE_PATH_RE = %r{
    ^/
    (gollum/)? # This path prefix was introduced in Gollum 5
    (create/|edit/|delete/|deleteFile/|rename/|revert/|uploadFile$|upload_file$)
  }x

  def call(env)
  request = Rack::Request.new(env)
    if(!(request.path =~ WRITE_PATH_RE))
      @app.call(env)  # skip auth
    else
      super           # perform auth
    end
  end
end

use SelectiveAuth, 'realm' do |username, password|
    if users.key?(username) && users[username] == Digest::SHA256.hexdigest(password)
        Precious::App.set(:loggedInUser, username)
    end
end

# This sets up a hook for post-commit due to gollum's broken git implementation
Gollum::Hook.register(:post_commit, :hook_id) do |committer, sha1|
  system('.git/hooks/post-commit')
end

Precious::App.set(:gollum_path, gollum_path)
Precious::App.set(:default_markup, :markdown)
Precious::App.set(:wiki_options, wiki_options)
Precious::App.set(:loggedInUser, 'Anonymous') # if the user is not logged in, default to Anonymous for logging
run Precious::App

# set author
class Precious::App
    before do
        session['gollum.author'] = {
            :name => "%s" % settings.loggedInUser
        }
    end
end

