module AresMUSH
  class WebApp   
    post '/wiki/:page/edit', :auth => :approved  do |name_or_id|
      @page = WikiPage.find_by_name_or_id(name_or_id)
      
      if (!@page)
        flash[:error] = "Page not found!"
        redirect '/wiki'
      end
      
      if (@page.is_special_page? && !is_admin?)
        flash[:error] = "You are not allowed to do that."
        redirect '/wiki'
      end 
      
      
      text = params[:text]
      tags = (params[:tags] || "").split(' ').map { |t| t.downcase }
      title = params[:title]
      name = params[:name]
      
      
      if (name.blank?)
        flash[:error] = "Page name cannot be empty."
        redirect "/wiki/#{@page.name}"
      end
      
      preview_data = {
        text: text,
        tags: params[:tags],
        title: title,
        name: name          
      }        
      
      if (@page.locked_by != @user)
        flash[:error] = "Your page lock has expired and someone else has started editing the page.  A copy of what you typed is below for you to copy/paste if you want to go back and try again."
        @page.update(draft: preview_data)
        redirect "/wiki/#{@page.name}/draft"
      end
      
      if (params[:preview])
        
        @page.update(preview: preview_data)
        redirect "/wiki/#{@page.name}/preview"
      end
      
      @page.update(tags: tags, title: title, name: name, html: nil, preview: {})
      WikiPageVersion.create(wiki_page: @page, text: text, character: @user)
      
      # Reset HTML of any pages that include this one
      WikiPage.all.select { |p| p.text =~ /\[\[include #{@page.name}/i }.each do |ref|
        ref.update(html: nil)
      end
    
      redirect "/wiki/#{@page.name}"
    end
    
    
    post '/wiki/create', :auth => :approved do
      text = params[:text]
      tags = (params[:tags] || "").split(' ').map { |t| t.downcase }
      title = params[:title]
      name = params[:name]
      
      if (name.blank?)
        flash[:error] = "Page name cannot be empty."
        redirect "/wiki/create"
      end
      
      existing = WikiPage.find_one_by_name(name)
      if (existing)
        flash[:error] = "A page with that name already exists!"
        redirect '/wiki/create'
      end
      
      new_page = WikiPage.create(title: title, name: name, tags: tags, html: nil, preview: {})
      WikiPageVersion.create(wiki_page: new_page, text: text, character: @user)
      
      redirect "/wiki/#{new_page.name}"
    end
    
  end
end