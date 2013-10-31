# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :espinita_audit, :class => 'Audit' do
    auditable nil
    user nil
    audited_changes "MyText"
    version 1
    remote_address "MyString"
  end
end
