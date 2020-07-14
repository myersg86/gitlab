# frozen_string_literal: true

module Vulnerabilities
  class LetterGrade
    attr_reader :vulnerable, :letter, :project_ids, :count

    def initialize(vulnerable, letter_grade, project_ids = [])
      @vulnerable = vulnerable
      @letter = ::Vulnerabilities::Statistic.letter_grades.key(letter_grade)
      @project_ids = project_ids
      @count = project_ids.size
    end

    def projects
      return [] if project_ids.blank?

      vulnerable.projects.where(id: project_ids)
    end

    def ==(other)
      letter == other.letter &&
        project_ids.to_set == other.project_ids.to_set
    end

    def self.defaults
      ::Vulnerabilities::Statistic
        .letter_grades
        .transform_values { |letter_grade| new(nil, letter_grade) }
    end

    def self.grades_for(vulnerable)
      vulnerable
        .projects
        .has_vulnerability_statistics
        .select(:id, :letter_grade)
        .group_by { |project| project.letter_grade }
        .map { |letter_grade, projects| new(vulnerable, letter_grade, projects.map(&:id)) }
        .to_h { |statistics| [statistics.letter, statistics] }
        .reverse_merge(defaults)
    end
  end
end
