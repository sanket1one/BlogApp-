require 'sinatra/base'
require 'sinatra/reloader'
require 'ostruct'
require 'time'
require 'yaml'
require 'redcarpet'
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'github_hook'

class MyApp < Sinatra::Base
    configure :development do
      register Sinatra::Reloader
    end
end

class Blog < Sinatra::Base 
    use GithubHook 

    enable :method_override
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

    get '/addBlog' do
        erb :addBlog
    end 

    post '/addBlog' do
        title = params[:title]
        content = params[:content]
        date = Date.today.strftime("%Y-%m-%d") # Format the date
        slug = title.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')

        metadata = {
            'title' => title,
            'date' => date
        }.to_yaml
        puts  title
        File.open("articles/#{slug}.md", 'w') do |file|
            file.puts metadata
            file.puts "\n"
            file.puts content
        end

        # Create an OpenStruct object for the new article
        article = OpenStruct.new YAML.safe_load(metadata, permitted_classes: [Date])
        article.date = Time.parse article.date.to_s
        article.content = content
        article.slug = slug

        # Append the new article to the articles list
        settings.articles << article

        redirect "/"

    end

    delete '/:slug' do
        slug = params[:slug]
        File.delete("articles/#{slug}.md") if File.exist?("articles/#{slug}.md")
        redirect "/"
    end

    get '/updateBlog/:slug' do
        slug = params[:slug]
        article = settings.articles.find { |a| a.slug == slug }
        erb :updateBlog, :locals => {:article => article }
    end

    put '/:slug' do
        slug = params[:slug]
        title = params[:title]
        content = params[:content]
        date = Date.today.strftime("%Y-%m-%d")  # Format the date
        new_slug = title.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')

        metadata = {
            'title' => title,
            'date' => date
        }.to_yaml

        File.open("articles/#{slug}.md", 'w') do |file|
            file.puts metadata
            file.puts "\n"
            file.puts content
        end

        # Find the article in the articles list and update it
        article = settings.articles.find { |a| a.slug == slug }
        if article
        article.title = title
        article.content = content
        article.date = Time.parse(date)
        article.slug = new_slug
        end

        if slug != new_slug
            File.rename("articles/#{slug}.md", "articles/#{new_slug}.md")
        end
    
        redirect "/"
    end
    
end

Blog.run! if __FILE__ == $0