FactoryGirl.define do
  factory :repository do
    url { Faker::Internet.url }
    module_name { Faker::Lorem.characters(16) }
    branch_name { Faker::Lorem.characters(16) }
    type 'GitRepository'
    #after(:create) { |instance| instance.update_attributes(best_code_set: create(:code_set, repository: instance)) }
  end
   factory :repo_with_code_set, parent: :repository do
    url { Faker::Internet.url }
    module_name { Faker::Lorem.characters(16) }
    branch_name { Faker::Lorem.characters(16) }
    type 'GitRepository'
    after(:create) { |instance| instance.update_attributes(best_code_set: create(:best_code_set, repository: instance)) }
  end
end
