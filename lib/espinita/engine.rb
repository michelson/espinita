module Espinita
  class Engine < ::Rails::Engine
    isolate_namespace Espinita
    
    config.generators do |g|
      g.test_framework  :rspec,
                        :fixture_replacement => :factory_girl ,
                        :dir => "spec/factories"
      g.integration_tool :rspec
    end

    initializer "include Auditor request into action controller" do |app|
      ActionController::Base.send(:include, Espinita::AuditorRequest)
      ActiveRecord::Base.send(:include, Espinita::Auditor)
    end


  end
end
