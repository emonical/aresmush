require_relative "../../plugin_test_loader"

module AresMUSH
  module HelpSystem
    describe HelpViewCmd do
      include PluginCmdTestHelper
      
      before do
        init_handler(HelpViewCmd, "help foo")
        SpecHelpers.stub_translate_for_testing        
      end
      
      it_behaves_like "a plugin that doesn't allow switches"
      
      describe :crack! do
        before do
          HelpSystem.stub(:category_for_command).with("help") { "cat" }
        end
        
        it "should find the category based on the root" do
          handler.crack!
          handler.category.should eq "cat"
        end        
        
        it "should clean up the help topic" do
          init_handler(HelpViewCmd, "help     whee FOO   ")
          handler.crack!
          handler.topic.should eq "Whee Foo"
        end
      end  
     
      describe :handle do  
        before do
          handler.stub(:category) { "cat" }
          handler.stub(:topic) { "topic" }
          AresMUSH::Locale.stub(:translate).with("help.topic", { :topic => "topic", :category => "cat title"}) { "topic title" }
          AresMUSH::Locale.stub(:translate).with("help.not_found_alternatives", { :topic => "topic" }) { "not found alternatives" }
          AresMUSH::Locale.stub(:translate).with("help.not_found", { :topic => "topic" }) { "not found" }
        end
        
        it "should display the topic if found" do
          HelpSystem.should_receive(:find_help).with("cat", "topic") { "help text"}
          HelpSystem.should_receive(:category_title).with("cat") { "cat title" }
          BorderedDisplay.should_receive(:text).with("help text", "topic title") { "output" }
          client.should_receive(:emit).with("output")
          handler.handle
        end
        
        it "should display possible alternatives if the topic is not found" do
          HelpSystem.should_receive(:find_help).with("cat", "topic") { nil }
          HelpSystem.should_receive(:search_topics).with("cat", "topic") { [ "A", "B" ]}
          BorderedDisplay.should_receive(:list).with([ "A", "B" ], "not found alternatives") { "output" }
          client.should_receive(:emit).with("output")
          handler.handle
        end

        it "should display error if no topic or alternatives found" do
          HelpSystem.should_receive(:find_help).with("cat", "topic") { nil }
          HelpSystem.should_receive(:search_topics).with("cat", "topic") { [] }
          client.should_receive(:emit_failure).with("not found")
          handler.handle
        end
      end
    end
  end
end