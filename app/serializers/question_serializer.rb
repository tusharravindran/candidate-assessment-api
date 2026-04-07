class QuestionSerializer < Blueprinter::Base
  identifier :id
  fields :body, :question_type, :points, :position
  association :question_options, blueprint: QuestionOptionSerializer

  view :with_answers do
    association :question_options, blueprint: QuestionOptionSerializer, view: :with_answer
  end
end
