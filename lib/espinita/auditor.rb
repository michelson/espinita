module Espinita
  module Auditor 
    extend ActiveSupport::Concern
    include Espinita::AuditorBehavior
  end
end

