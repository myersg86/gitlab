# TODO consider extending IssuableEntity - some changes woud be needed there
# probably not epics: lock_version, milestone, time_estimate, total_time_spent,
# human_time_estimate, human_total_time_spent
class EpicEntity < Grape::Entity
  expose :id
  expose :iid
  expose :author_id
  expose :title
  expose :description
  expose :group_id
  expose :state
  expose :start_date
  expose :end_date
end
