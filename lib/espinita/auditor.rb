module Espinita
  module Auditor 
    extend ActiveSupport::Concern
    include Espinita::AuditorBehavior

    included do
      has_many :audits, :as => :auditable, :class_name => Espinita::Audit.name
      #attr_accessor :audited_user, :audited_ip
      accepts_nested_attributes_for :audits
    end

    module ClassMethods
     
    end

  end
end

