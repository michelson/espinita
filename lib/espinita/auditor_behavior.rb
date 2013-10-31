module Espinita
  module AuditorBehavior
    extend ActiveSupport::Concern

    included do 
      class_attribute  :excluded_cols
      class_attribute  :audit_callbacks
      attr_accessor :audit_comment
    end

    module ClassMethods

      @@default_excluded = %w(lock_version created_at updated_at created_on updated_on)

      def auditable(options = {})

        self.audit_callbacks = []
        self.audit_callbacks << options[:on] unless options[:on].blank?
        self.audit_callbacks.flatten!

        after_create   :audit_create  if self.audit_callbacks.blank? || self.audit_callbacks.include?(:create)
        before_update  :audit_update  if self.audit_callbacks.blank? || self.audit_callbacks.include?(:update)
        before_destroy :audit_destroy if self.audit_callbacks.blank? || self.audit_callbacks.include?(:destroy)
          
        self.excluded_cols   = (@@default_excluded)

        if options[:only]
          options[:only] = [options[:only]].flatten.map { |x| x.to_s }
          self.excluded_cols = (self.column_names - options[:only] ) 
        end

        if options[:except]
          options[:except] = [options[:except]].flatten.map { |x| x.to_s }
          self.excluded_cols = (@@default_excluded) + options[:except]
        end

      end

      def permited_columns
        self.column_names - self.excluded_cols.to_a
      end

      # All audits made during the block called will be recorded as made
      # by +user+. This method is hopefully threadsafe, making it ideal
      # for background operations that require audit information.
      def as_user(user, &block)
        RequestStore.store[:audited_user] = user
        yield
      ensure
        RequestStore.store[:audited_user] = nil
      end

    end

    # audited attributes detected against permited columns
    def audited_attributes
      self.changes.keys & self.class.permited_columns
    end


    def audit_create
      puts self.class.audit_callbacks
      write_audit(:action => 'create', :audited_changes => changes,
                  :comment => audit_comment)
    end

    def audit_update
      puts self.class.audit_callbacks
      write_audit(:action => 'update', :audited_changes => changes,
                    :comment => audit_comment)
    end

    def audit_destroy
      write_audit(:action => 'destroy', :audited_changes => changes,
                  :comment => audit_comment)
    end

    def write_audit(options)
      self.audits.create(options) unless audited_attributes.blank?
    end

  end
end