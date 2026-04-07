class QuestionOptionSerializer < Blueprinter::Base
  identifier :id
  fields :body, :position

  # Only include :correct when rendering for recruiter context
  view :with_answer do
    field :correct
  end
end
