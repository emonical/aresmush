module AresMUSH
  module Login
    class CreateCmd
      include AresMUSH::Plugin
      
      attr_accessor :charname, :password

      # Validators
      no_switches
      
      def want_command?(client, cmd)
        cmd.root_is?("create")
      end

      def crack!
        cmd.crack!(/(?<name>\S+) (?<password>.+)/)
        self.charname = cmd.args.name
        self.password = cmd.args.password
      end
      
      def validate_not_already_logged_in
        return t("login.already_logged_in") if client.logged_in?
        return nil
      end      
      
      def validate_name
        return t('login.invalid_create_syntax') if charname.nil?
        return Login.validate_char_name(charname)
      end
      
      def validate_password
        return t('login.invalid_create_syntax') if password.nil?
        return Login.validate_char_password(password)
      end
      
      def handle        
        char = Character.new
        char.name = charname
        char.change_password(password)
        char.save!
        
        client.emit_success(t('login.created_and_logged_in', :name => charname))
        client.char = char
        Global.dispatcher.on_event(:char_created, :client => client)
        Global.dispatcher.on_event(:char_connected, :client => client)        
      end
      
      def log_command
        # Don't log full command for privacy
        Global.logger.debug("#{self.class.name} #{client}")
      end      
    end
  end
end