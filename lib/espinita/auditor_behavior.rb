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

        has_many :audits, :as => :auditable, :class_name => Espinita::Audit.name
        #attr_accessor :audited_user, :audited_ip
        accepts_nested_attributes_for :audits

      end

      def permitted_columns
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

    def history_from_audits_for(attributes)
      attributes = Array(attributes) unless attributes.is_a?(Array)  # convert single attributes to arrays [:myProp]
      attributes = attributes.map{ |p| p.to_s } # for consistency, ensure that we're working with strings, not symbols
      raise ArgumentError, "One or more of the specified columns do not exist or are not audited." if (attributes - self.class.permitted_columns).any?

      audits = self.audits
        .sort_by{ |a| a.created_at }.reverse # most recent first
        .select{ |a| attributes.any?{ |p| a.audited_changes.key?(p.to_sym) } }

      property_history = audits.map do |a|
        result = Hash.new
        (a.audited_changes.keys.map{|k|k.to_s} & attributes).each do |key|
          result[key.to_sym] = a.audited_changes[key.to_sym].last
        end
        result[:changed_at] = a.created_at.localtime.strftime('%Y-%m-%dT%l:%M:%S%z')
        result
      end
      return property_history
    end

    def restore_attributes!(attributes, datetime)
      attributes = Array(attributes) unless attributes.is_a?(Array)  # convert single attributes to arrays [:myProp]
      attributes = attributes.map{ |p| p.to_s } # for consistency, ensure that we're working with strings, not symbols

      changes = {}

      attributes.each do |attrib|
        audits = self.audits
          .sort_by{ |a| a.created_at }.reverse
          .select{ |a| a.audited_changes.key?(attrib.to_sym).present? }
        audits.each do |a|
          if a.created_at < datetime
            restore_val = a.audited_changes[attrib.to_sym].last
            unless restore_val == self[attrib]
              changes[attrib] = restore_val
            end
            break # successfully restored from an audit - exit now
          end
        end
        if !changes[attrib].present? && (datetime < audits.last.created_at)
          changes[attrib] = audits.last.audited_changes[attrib.to_sym].first
        end
      end

      self.update_attributes(changes)
      return changes.keys.count > 0
    end

    # audited attributes detected against permitted columns
    def audited_attributes
      self.changes.keys & self.class.permitted_columns
    end

    def audited_hash
      Hash[ audited_attributes.map{|o| [o.to_sym, self.changes[o.to_sym] ] } ]
    end


    def audit_create
      #puts self.class.audit_callbacks
      write_audit(:action => 'create',
                  :audited_changes => audited_hash,
                  :comment => audit_comment)
    end

    def audit_update
      #puts self.class.audit_callbacks
      write_audit(:action => 'update',
                  :audited_changes => audited_hash,
                  :comment => audit_comment)
    end

    def audit_destroy
      comment_description = ["deleted model #{id}", audit_comment].join(": ")
      write_audit(:action => 'destroy',
                  :audited_changes => self.attributes,
                  :comment => comment_description )
    end

    def write_audit(options)
      self.audits.create(options) unless options[:audited_changes].blank?
    end

  end
end