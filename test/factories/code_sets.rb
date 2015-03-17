FactoryGirl.define do
  factory :code_set do
    association :repository
    #association :fyle     
  end
  factory :best_code_set, parent: :code_set do
  	after(:create) { |instance| instance.fyles << create(:fyle) }
  end
end
