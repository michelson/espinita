module Espinita::AuditorRequest 
  extend ActiveSupport::Concern

  included do 
    before_action :store_audited_user
  end

  def store_audited_user

    # assign current_user if defined
    RequestStore.store[:audited_user] = self.send(Espinita.current_user_method) if self.respond_to?(Espinita.current_user_method, include_private = true)
    
    RequestStore.store[:audited_ip]   = self.try(:request).try(:remote_ip)
  end
end
