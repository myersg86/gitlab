# frozen_string_literal: true

class Ci::Yaml::LintEntity < Grape::Entity
  expose :valid?, as: :valid
  expose :errors
  expose :config, using: Ci::Yaml::ConfigEntity
end
