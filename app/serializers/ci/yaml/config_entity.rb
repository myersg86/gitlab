# frozen_string_literal: true

class Ci::Yaml::ConfigEntity < Grape::Entity
  expose :jobs
  expose :builds
  expose :stages
end
