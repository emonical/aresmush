module AresMUSH
  class WebApp
    
    get '/admin/shutdown/?', :auth => :admin do
      path = File.join( AresMUSH.root_path, "bin", "killares" )
      `#{path}`
      "" # We'll never return
    end
    
  end
end
