module AresMUSH
  module Manage
    class LoadLocaleCmd
      include AresMUSH::Plugin

      # Validators
      must_be_logged_in
      
      def want_command?(client, cmd)
        cmd.root_is?("load") && cmd.switch == "locale"
      end

      # TODO - validate permissions
      
      def handle
        begin
          Global.locale.load!
          client.emit_success t('manage.locale_loaded')
        rescue Exception => e
          client.emit_failure t('manage.error_loading_locale', :error => e.to_s)
        end
      end
    end
  end
end