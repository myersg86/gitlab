# frozen_string_literal: true

module Vulnerabilities
  class ProjectsGrade
    attr_reader :vulnerable, :grade, :project_ids

    def initialize(vulnerable, letter_grade, project_ids = [])
      @vulnerable = vulnerable
      @grade = letter_grade
      @project_ids = project_ids
    end

    def projects
      return vulnerable.projects.none if project_ids.blank?

      vulnerable.projects.where(id: project_ids)
    end

    def self.grades_for(vulnerables)
      ::Vulnerabilities::Statistic
        .for_project(vulnerables.map(&:projects).reduce(&:or))
        .group(:letter_grade)
        .select(:letter_grade, 'array_agg(project_id) project_ids')
        .flat_map do |statistics|
          vulnerables.map do |vulnerable|
            new(vulnerable, statistics.letter_grade, statistics.project_ids)
          end
        end
    end
  end
end
