$:.unshift File.dirname(__FILE__)
load "engine/map_cmd.rb"
load "engine/maps_cmd.rb"
load "engine/maps_model.rb"
load "engine/map_create_cmd.rb"
load "engine/map_delete_cmd.rb"
load "engine/map_areas_cmd.rb"
load "lib/helpers.rb"
load "web/maps.rb"

module AresMUSH
  module Maps
    def self.plugin_dir
      File.dirname(__FILE__)
    end
 
    def self.shortcuts
      Global.read_config("maps", "shortcuts")
    end
 
    def self.load_plugin
      self
    end
 
    def self.unload_plugin
    end
    
    def self.config_files
      [ "config_maps.yml" ]
    end
 
    def self.locale_files
      [ "locales/locale_en.yml" ]
    end
 
    def self.get_cmd_handler(client, cmd, enactor)
       case cmd.root
       when "map"
         case cmd.switch
         when "create"
           return MapCreateCmd
         when "delete"
           return MapDeleteCmd
         when "area"
           return MapAreasCmd
         when nil
           return MapCmd
         end
       when "maps"
         return MapsCmd
       end
       nil
    end

    def self.get_event_handler(event_name) 
      nil
    end
  end
end