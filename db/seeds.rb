# Create a demo organization and recruiter
org = Organization.find_or_create_by!(slug: "demo-corp") do |o|
  o.name = "Demo Corp"
end

recruiter = Recruiter.find_or_create_by!(email: "admin@demo.com") do |r|
  r.name = "Admin User"
  r.password = "password123"
  r.password_confirmation = "password123"
  r.organization = org
  r.role = "admin"
end

# Create a sample assessment
assessment = org.assessments.find_or_create_by!(title: "Ruby Developer Assessment") do |a|
  a.description = "A technical assessment for Ruby developers"
  a.time_limit_minutes = 45
  a.passing_score = 70
  a.recruiter = recruiter
end

# Add questions
q1 = assessment.questions.find_or_create_by!(body: "What is the result of 2 + 2 in Ruby?") do |q|
  q.question_type = "multiple_choice"
  q.points = 1
  q.position = 0
  q.organization = org
end

q1.question_options.find_or_create_by!(body: "4", correct: true, position: 0, organization: org)
q1.question_options.find_or_create_by!(body: "5", correct: false, position: 1, organization: org)
q1.question_options.find_or_create_by!(body: "22", correct: false, position: 2, organization: org)
q1.question_options.find_or_create_by!(body: "3", correct: false, position: 3, organization: org)

q2 = assessment.questions.find_or_create_by!(body: "Is Ruby an object-oriented language?") do |q|
  q.question_type = "true_false"
  q.points = 1
  q.position = 1
  q.organization = org
end

q2.question_options.find_or_create_by!(body: "True", correct: true, position: 0, organization: org)
q2.question_options.find_or_create_by!(body: "False", correct: false, position: 1, organization: org)

q3 = assessment.questions.find_or_create_by!(body: "Explain the difference between include and extend in Ruby.") do |q|
  q.question_type = "free_text"
  q.points = 3
  q.position = 2
  q.organization = org
end

puts "Seeds complete: org=#{org.name}, recruiter=#{recruiter.email}, assessment=#{assessment.title}"
