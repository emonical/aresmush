module AresMUSH

  module Describe
    class OutfitSetCmd
      include CommandHandler
      
      attr_accessor :name, :desc
      
      def parse_args
        args = cmd.parse_args(ArgParser.arg1_equals_arg2)
        self.name = titlecase_arg(args.arg1)
        self.desc = args.arg2
      end
      
      def required_args
        [ self.name, self.desc ]
      end
      
      def check_single_word_names
        return t('describe.outfits_only_one_word') if self.name.split.size > 1
        return nil
      end
      
      def handle
        outfit = enactor.outfit(self.name)
        if (!outfit)
          outfit = enactor.create_desc(:outfit, desc, self.name)
        else
           outfit.update(description: desc)
        end
        client.emit_success t('describe.outfit_set')
      end
    end
  end
end
