Wiki::Plugin.define 'misc/simple_search' do
  Wiki::App.class_eval do
    get '/search' do
      matches = @repo.grep(params[:pattern], nil, :ignore_case => true)
      @matches = []
      matches.each_pair do |id,lines|
        if id =~ /^.+?:(.+)$/
          @matches << [$1,lines.map {|x| x[1] }.join("\n").truncate(100)]
        end
      end
      haml :search
    end
  end
end
