# frozen_string_literal: true

module Vulnerabilities
  class LetterGrade
    attr_reader :vulnerable, :grade, :project_ids, :count

    def initialize(vulnerable, letter_grade, project_ids = [])
      @vulnerable = vulnerable
      @grade = ::Vulnerabilities::Statistic.letter_grades.key(letter_grade)
      @project_ids = project_ids
      @count = project_ids.size
    end

    def projects
      return vulnerable.projects.none if project_ids.blank?

      vulnerable.projects.where(id: project_ids)
    end

    def ==(other)
      grade == other.grade &&
        project_ids.to_set == other.project_ids.to_set
    end

    def self.defaults
      ::Vulnerabilities::Statistic
        .letter_grades
        .map { |_, letter_grade| new(nil, letter_grade) }
    end

    def self.grades_for(vulnerable)
      vulnerable
        .projects
        .has_vulnerability_statistics
        .select(:id, :letter_grade)
        .group_by { |project| project.letter_grade }
        .map { |letter_grade, projects| new(vulnerable, letter_grade, projects.map(&:id)) }
    end
  end
end
