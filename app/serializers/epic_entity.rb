# TODO consider extending IssuableEntity / Issue
class EpicEntity < Grape::Entity
  expose :id
  expose :author_id
  expose :title
  expose :description
  expose :group_id
  expose :state
  expose :start_date
  expose :end_date
end
