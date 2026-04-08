require "rails_helper"

RSpec.describe AdminUser, type: :model do
  it "is valid with an email and password" do
    admin_user = described_class.new(
      email: "platform-admin@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    expect(admin_user).to be_valid
  end
end
