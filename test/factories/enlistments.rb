FactoryGirl.define do
  factory :enlistment do
    association :project
    association :repository
    deleted false
    before(:create) { |instance| instance.editor_account = create(:admin) }
  end
   factory :enlistment_with_code_set, parent: :enlistment do
    association :project
    association :repository
    deleted false
    before(:create) { |instance| instance.editor_account = create(:admin) }
    after(:create){|instance| instance.repository = create(:repo_with_code_set)}
  end
end
