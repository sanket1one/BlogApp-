require 'sinatra/base'
require 'time'

#Regenerating content
class GithubHook < Sinatra::Base
    def self.parse_git
        # Parse hash and date from the git log command.
        sha1 , date = `git log Head~1..HEAD --pretty=format:%h^ci`.split('^')
        set :commit_hash,sha1
        set :commit_date,date
    end

    set(:autopull) {production?}
    parse_git

    before do 
        cache_control :public, :must_revalidate
        etag settings.commit_hash
        last_modified settings.commit_date
    end 

    post '/update' do
        settings.parse_git

        app.settings.reset!
        load app.settings.app_file

        content_type :txt
        if settings.autopull?
            #Pipe stderr to stdout to make sure we display everything.
            `git pull 2>&1`
        else 
            "ok" 
        end
    end 
end