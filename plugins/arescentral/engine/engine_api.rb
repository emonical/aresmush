module AresMUSH
  class EngineApiServer
    
    helpers do 
      def check_api_key
        params[:api_key] == Game.master.engine_api_key
      end
    end
    
    get '/api/who' do 
      who = Engine.client_monitor.logged_in.map { |client, char| char.name }
      { who: who }.to_json
    end
      
    post '/api/char/created' do
      Engine.dispatcher.queue_event CharCreatedEvent.new(nil, params['id'])
      { status: 'OK', error: '' }.to_json
    end
    
    post '/api/notify' do
      if (!check_api_key)
        return { status: 'ERROR', error: 'Invalid authentication token.'}.to_json
      end

      type = params['type']
      char_ids = (params['chars'] || '').split(',')
      msg = params['message']
      ooc = params['ooc'].to_bool

      if (ooc)
        Global.notifier.notify_ooc(type, msg) do |char|
          char && char_ids.include?(char.id)
        end
      else
        Global.notifier.notify(type, msg) do |char|
          char && char_ids.include?(char.id)
        end
      end      
      {status: 'OK'}.to_json
    end
    
    post '/api/config/load' do
      
      if (!check_api_key)
        return { status: 'ERROR', error: 'Invalid authentication token.'}.to_json
      end
      
      error = Manage.reload_config
      { status: error ? 'ERROR' : 'OK', error: error }.to_json            
    end
    
    post '/api/tinker/load' do
      if (!check_api_key)
        return { status: 'ERROR', error: 'Invalid authentication token.'}.to_json
      end

      error = nil
      begin
        begin
          Global.plugin_manager.unload_plugin("tinker")
        rescue SystemNotFoundException
          # Swallow this error.  Just means you're loading a plugin for the very first time.
        end
        # Make sure everything is valid before we start.
        Global.config_reader.validate_game_config          
        Global.plugin_manager.load_plugin("tinker", :engine)
        Global.config_reader.load_game_config        
      rescue Exception => ex
        Global.logger.error ex
        error = ex.to_s
      end
      { status: error ? 'ERROR' : 'OK', error: error }.to_json      
    end

    post '/api/char/created' do
      if (!check_api_key)
        return { status: 'ERROR', error: 'Invalid authentication token.'}.to_json
      end
      
      Engine.dispatcher.queue_event CharCreatedEvent.new(nil, params['id'])
      { status: 'OK', error: '' }.to_json
    end
    
    post '/api/plugins/changed' do
      if (!check_api_key)
        return { status: 'ERROR', error: 'Invalid authentication token.'}.to_json
      end

      changed = params['changed_plugins'].split(",")
      
      begin
        # Make sure everything is valid before we start.
        Global.config_reader.validate_game_config          
        Global.config_reader.load_game_config   
        changed.each do |p|
          begin
            Global.plugin_manager.unload_plugin(p)
          rescue SystemNotFoundException
            # Swallow this error.  Just means you're loading a plugin for the very first time.
          end
          Global.plugin_manager.load_plugin(p, :engine)
        end      
        Help.reload_help
        Global.locale.reload
        Engine.dispatcher.queue_event ConfigUpdatedEvent.new
      rescue Exception => ex
        Global.logger.error ex
        error = ex.to_s
      end
      { status: error ? 'ERROR' : 'OK', error: error }.to_json   
    end

  end
end