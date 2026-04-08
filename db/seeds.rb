# ── Platform Admin ─────────────────────────────────────────────────────────────
# This is the super-admin account for /admin (RailsAdmin).
# It has no tenant — it can see and manage all organizations.
platform_admin = AdminUser.find_or_create_by!(email: "platform@admin.com") do |a|
  a.password = "PlatformAdmin123!"
  a.password_confirmation = "PlatformAdmin123!"
end
puts "Platform admin: #{platform_admin.email} / PlatformAdmin123!"

# ── Demo Tenant ────────────────────────────────────────────────────────────────
# Represents a customer organization (one tenant).
org = Organization.find_or_create_by!(slug: "demo-corp") do |o|
  o.name    = "Demo Corp"
  o.plan    = "pro"
  o.domain  = "demo-corp.com"
  o.active  = true
end

# Tenant admin recruiter — manages assessments, can review free-text answers
admin_recruiter = Recruiter.find_or_create_by!(email: "admin@demo.com") do |r|
  r.name                  = "Alice Admin"
  r.password              = "password123"
  r.password_confirmation = "password123"
  r.organization          = org
  r.role                  = "admin"
end
puts "Tenant admin recruiter: #{admin_recruiter.email} / password123"

# Tenant member recruiter — can create assessments and send invitations,
# but cannot submit manual reviews (admin-only)
member_recruiter = Recruiter.find_or_create_by!(email: "recruiter@demo.com") do |r|
  r.name                  = "Bob Recruiter"
  r.password              = "password123"
  r.password_confirmation = "password123"
  r.organization          = org
  r.role                  = "member"
end
puts "Tenant member recruiter: #{member_recruiter.email} / password123"

# ── Demo Assessment ────────────────────────────────────────────────────────────
assessment = org.assessments.find_or_create_by!(title: "Ruby Developer Assessment") do |a|
  a.description         = "A technical assessment for Ruby developers"
  a.time_limit_minutes  = 45
  a.passing_score       = 70
  a.recruiter           = admin_recruiter
end

q1 = assessment.questions.find_or_create_by!(body: "What is the result of 2 + 2 in Ruby?") do |q|
  q.question_type = "multiple_choice"
  q.points        = 1
  q.position      = 0
  q.organization  = org
end
q1.question_options.find_or_create_by!(body: "4",  correct: true,  position: 0, organization: org)
q1.question_options.find_or_create_by!(body: "5",  correct: false, position: 1, organization: org)
q1.question_options.find_or_create_by!(body: "22", correct: false, position: 2, organization: org)
q1.question_options.find_or_create_by!(body: "3",  correct: false, position: 3, organization: org)

q2 = assessment.questions.find_or_create_by!(body: "Is Ruby an object-oriented language?") do |q|
  q.question_type = "true_false"
  q.points        = 1
  q.position      = 1
  q.organization  = org
end
q2.question_options.find_or_create_by!(body: "True",  correct: true,  position: 0, organization: org)
q2.question_options.find_or_create_by!(body: "False", correct: false, position: 1, organization: org)

q3 = assessment.questions.find_or_create_by!(body: "Explain the difference between include and extend in Ruby.") do |q|
  q.question_type = "free_text"
  q.points        = 3
  q.position      = 2
  q.organization  = org
end

puts "Assessment: #{assessment.title} (#{assessment.status})"
puts ""
puts "────────────────────────────────────────"
puts "Seed credentials summary"
puts "────────────────────────────────────────"
puts "Platform admin (RailsAdmin at /admin):"
puts "  Email:    platform@admin.com"
puts "  Password: PlatformAdmin123!"
puts ""
puts "Tenant: #{org.name} (#{org.slug})"
puts "  Admin recruiter:  admin@demo.com / password123"
puts "  Member recruiter: recruiter@demo.com / password123"
puts "────────────────────────────────────────"
