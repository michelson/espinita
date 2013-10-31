class CreateAuditableAudits < ActiveRecord::Migration
  def change
    create_table :espinita_audits do |t|
      t.references :auditable, polymorphic: true, index: true
      t.references :user, polymorphic: true, index: true
      t.text :audited_changes
      t.string :comment
      t.integer :version
      t.string :action
      t.string :remote_address

      t.timestamps
    end
  end
end
