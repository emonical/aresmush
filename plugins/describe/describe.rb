$:.unshift File.dirname(__FILE__)

module AresMUSH
  module Describe
    def self.plugin_dir
      File.dirname(__FILE__)
    end
 
    def self.shortcuts
      Global.read_config("describe", "shortcuts")
    end
 
    def self.load_plugin
      self
    end
 
    def self.unload_plugin
    end
 
    def self.get_cmd_handler(client, cmd, enactor)
      case cmd.root
      when "describe", "shortdesc"
        case cmd.switch
        when "edit"
          return DescEditCmd
        when "notify"
          return DescNotifyCmd
        when nil
          return DescCmd
        end
      when "detail"
        case cmd.switch
        when "delete"
          return DetailDeleteCmd
        when "edit"
          return DetailEditCmd
        when "set"
          return DetailSetCmd
        when nil
          return LookCmd
        end
      when "glance"
        return GlanceCmd
      when "look"
        return LookCmd
      when "outfit"
        case cmd.switch
        when "delete"
          return OutfitDeleteCmd
        when "edit"
          return OutfitEditCmd
        when "set"
          return OutfitSetCmd
        when nil
          if (cmd.args)
            return OutfitViewCmd
          else
            return OutfitListCmd
          end
        end
      when "wear"
        return WearCmd
      end
      
      nil
    end

    def self.get_event_handler(event_name) 
      nil
    end
  end
end
