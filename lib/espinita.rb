require "espinita/engine"
require "request_store"

module Espinita

  autoload :Auditor, "espinita/auditor"
  autoload :AuditorBehavior, "espinita/auditor_behavior"
  autoload :AuditorRequest, "espinita/auditor_request"

  class << self

    attr_accessor :current_user_method
   
    def current_user_method
      @current_user_method ||= :current_user
    end

  end

end
