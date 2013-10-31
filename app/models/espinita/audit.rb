module Espinita
  class Audit < ActiveRecord::Base
    belongs_to :auditable, polymorphic: true
    belongs_to :user, polymorphic: true


    scope :descending,    ->{ reorder("version DESC")}
    scope :creates,       ->{ where({:action => 'create'})}
    scope :updates,       ->{ where({:action => 'update'})}
    scope :destroys,      ->{ where({:action => 'destroy'})}

    scope :up_until,      ->(date_or_time){where("created_at <= ?", date_or_time) }
    scope :from_version,  ->(version){where(['version >= ?', version]) }
    scope :to_version,    ->(version){where(['version <= ?', version]) }
    scope :auditable_finder, ->(auditable_id, auditable_type){where(auditable_id: auditable_id, auditable_type: auditable_type)}

    serialize :audited_changes

    before_create :set_version_number, :set_audit_user

    # Return all audits older than the current one.
    def ancestors
      self.class.where(['auditable_id = ? and auditable_type = ? and version <= ?',
        auditable_id, auditable_type, version])
    end

  private
    def set_version_number
      max = self.class.auditable_finder(auditable_id, auditable_type).maximum(:version) || 0
      self.version = max + 1
    end

    def set_audit_user
      self.user           = RequestStore.store[:audited_user] if RequestStore.store[:audited_user]
      self.remote_address = RequestStore.store[:audited_ip]   if RequestStore.store[:audited_ip]

      nil # prevent stopping callback chains
    end

  end
end
