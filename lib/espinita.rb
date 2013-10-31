require "espinita/engine"
require "request_store"

module Espinita

  autoload :Auditor, "espinita/auditor"
  autoload :AuditorBehavior, "espinita/auditor_behavior"
  autoload :AuditorRequest, "espinita/auditor_request"

  attr_accessor :current_user_method
 
  def self.current_user_method
    @current_user_method ||= :current_user
  end

end
