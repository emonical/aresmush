module AresMUSH
  class Game < Ohm::Model
    include ObjectModel

    reference :system_character, "AresMUSH::Character"
    reference :master_admin, "AresMUSH::Character"
    
    # These are used when communicating with AresCentral
    attribute :api_game_id
    attribute :api_key
    
    # This is used when the web portal communicates with the engine
    attribute :engine_api_key
    
    # There's only one game document and this is it!
    def self.master
      Game[1]
    end
    
    def is_special_char?(char)
      return true if char == system_character
      return true if char == master_admin
      return false
    end
    
    def self.web_portal_url
      Global.read_config("game", "website")
    end    
  end
end
