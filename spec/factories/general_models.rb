# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :general_model do
    user nil
    name "MyString"
    settings "MyText"
    position 1
  end
end
