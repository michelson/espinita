# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    name "John"
    last_name "Afferson"
    email "john@afferson.com"
  end
end
