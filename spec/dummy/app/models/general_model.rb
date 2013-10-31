class GeneralModel < ActiveRecord::Base
  belongs_to :user
  include Espinita::Auditor
end
