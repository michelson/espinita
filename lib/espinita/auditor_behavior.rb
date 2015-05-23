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
      attributes = arrayify(attributes)
      attributes = attributes.map(&:to_s) # for consistency, ensure that we're working with strings, not symbols
      raise ArgumentError, "At least one of the specified columns does not exist or is not audited." if (attributes - self.class.permitted_columns).any?

      audits = relevant_audits(self.audits, attributes)

      property_history = audits.map do |a|
        {
          changes: Hash[
            (a.audited_changes.keys.map(&:to_s) & attributes).map do |key|
              [key.to_sym, a.audited_changes[key.to_sym].last]
            end
          ],
          changed_at: a.created_at.localtime
        }
      end
      return property_history
    end

    def restore_attributes!(attributes, datetime)
      attributes = arrayify(attributes)
      attributes = attributes.map(&:to_s) # for consistency, ensure that we're working with strings, not symbols
      raise ArgumentError, "At least one of the specified columns does not exist or is not audited." if (attributes - self.class.permitted_columns).any?

      changes = {}

      attributes.each do |attrib|
        audits = relevant_audits(self.audits, [attrib])
        audit = audits.select{ |a| a.created_at < datetime }.first

        if audit.present? # restore to the requested point in time
          restore_val = audit.audited_changes[attrib.to_sym].last
        else # or fall back to the initial state of the record if the requested time predates the first audit
          restore_val = audits.last.audited_changes[attrib.to_sym].first
        end

        unless restore_val == self[attrib]
          changes[attrib] = restore_val
        end
      end

      self.update_attributes(changes)
      return changes.keys.count > 0
    end

    def restore_to_audit(id_or_record)
      audit = self.audits.find(id_or_record)

      audit.ancestors.each do |ancestor|
        self.assign_attributes Hash[ancestor.audited_changes.map{ |k,v| [k,v[0]] }]
      end

      self.save
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

    private

      def arrayify(item_or_array) # convert single attributes to arrays [:myProp]
        if item_or_array.is_a?(Array)
          return item_or_array
        else
          return Array(item_or_array)
        end
      end

      def relevant_audits(audits, attributes)
        audits
          .order('created_at DESC') # most recent first
          .select{ |a| attributes.any?{ |p| a.audited_changes.key?(p.to_sym) } }
      end

  end
end