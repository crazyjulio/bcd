# Read about factories at http://github.com/thoughtbot/factory_girl
FactoryGirl.define do
  factory :download do
    product_id 1
    user_id 1
    count 1
    remaining 4
  end
end
