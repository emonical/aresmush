module AresMUSH
  class SpeechBracketExtension
    def self.regex
      /<<([^<]+)>>/i
    end
      
    def self.parse(matches, sinatra)
      text = matches[1]
      "_&lt;&lt;#{text}&gt;&gt;_"
    end
  end
end