module AresMUSH
  module Who
    class WhereCmd
      include CommandHandler
      
      attr_accessor :search
      
      def parse_args
        self.search = titlecase_arg(cmd.args)
      end
      
      def allow_without_login
        true
      end
      
      def handle
        online_chars = Engine.client_monitor.logged_in.map { |client, char| char }
        if (self.search)
          online_chars = online_chars.select { |char| char.name =~ /^#{search}/  }
        end
        template = WhereTemplate.new online_chars
        client.emit template.render
      end      
    end
  end
end
