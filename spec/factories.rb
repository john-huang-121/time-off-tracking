FactoryBot.define do
  factory :department do
    sequence(:name) { |n| "#{Faker::Commerce.department} #{n}" }
  end

  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    role { :employee }

    trait :employee do
      role { :employee }
    end

    trait :manager do
      role { :manager }
    end

    trait :admin do
      role { :admin }
    end

    trait :with_profile do
      after(:create) do |user|
        create(:profile, user: user)
      end
    end
  end

  factory :profile do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    birth_date { Faker::Date.birthday(min_age: 22, max_age: 65) }
    phone_number { Faker::PhoneNumber.phone_number }

    association :user
    association :department

    trait :with_manager do
      after(:create) do |profile|
        manager_user = create(:user, :manager, :with_profile)
        profile.update(manager_id: manager_user.id)
      end
    end

    trait :with_department do
      after(:create) do |profile|
        department = create(:department)
        profile.update(department_id: department.id)
      end
    end
  end

  factory :time_off_request do
    start_date { Date.current + 7.days }
    end_date { Date.current + 9.days }
    time_off_type { :vacation }
    status { :pending }
    reason { Faker::Lorem.sentence }

    association :user

    trait :pending do
      status { :pending }
    end

    trait :approved do
      status { :approved }
      after(:create) do |request|
        reviewer = create(:user, :manager, :with_profile)
        create(:approval, time_off_request: request, reviewer: reviewer, decision: :approved)
      end
    end

    trait :denied do
      status { :denied }
      after(:create) do |request|
        reviewer = create(:user, :manager, :with_profile)
        create(:approval, time_off_request: request, reviewer: reviewer, decision: :denied)
      end
    end

    trait :canceled do
      status { :canceled }
      after(:create) do |request|
        create(:approval, time_off_request: request, reviewer: request.user, decision: :canceled)
      end
    end

    trait :vacation do
      time_off_type { :vacation }
    end

    trait :sick do
      time_off_type { :sick }
    end

    trait :personal do
      time_off_type { :personal }
    end
  end

  factory :approval do
    decision { :approved }
    comment { Faker::Lorem.sentence }

    association :time_off_request
    association :reviewer, factory: [ :user, :manager ]

    trait :approved do
      decision { :approved }
    end

    trait :denied do
      decision { :denied }
    end

    trait :canceled do
      decision { :canceled }
    end
  end
end
