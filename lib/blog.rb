require 'sinatra/base'
require 'ostruct'
require 'time'
require 'yaml'
require 'redcarpet'
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'github_hook'

class Blog < Sinatra::Base 
    use GithubHook 

    set :root, File.expand_path('../../',__FILE__)
    set :articles,[]
    set :app_file,__FILE__

    # method to parse the markdown used in post.erb
    helpers do
        def markdown(text)
          Redcarpet::Markdown.new(Redcarpet::Render::HTML).render(text)
        end
    end

    #loop through all the articel files
    Dir.glob "#{root}/articles/*.md" do |file|
        #parse meta data and content from file
        #generate a metadata object
        #convert the date to a time object
        # add the content
        # generate a slug from the url
        meta,content = File.read(file).split("\n\n",2)
        article = OpenStruct.new YAML.safe_load(meta, permitted_classes: [Date])
        article.date = Time.parse article.date.to_s
        article.content = content
        article.slug = File.basename(file,'.md')

        #set up the route
        get "/#{article.slug}" do
            erb :post, :locals => {:article => article }
        end

        # Add article to list of articles
        articles << article
    end

    # Sort the artcles by date, display new articles first
    articles.sort_by! {|article| article.date}
    articles.reverse!

    get '/' do
        erb :index
    end

end

Blog.run! if __FILE__ == $0