# frozen_string_literal: true

class Assessment < ApplicationRecord
  include TenantScoped

  has_many :assessment_skills, dependent: :destroy, inverse_of: :assessment
  has_many :sessions, dependent: :restrict_with_error

  SUPPORTED_LANGUAGES = { 'en' => 'English', 'id' => 'Bahasa Indonesia' }.freeze

  validates :name, presence: true
  validates :time_limit_min, presence: true,
                              inclusion: { in: [10, 30, 45, 60, 90] }
  validates :language, inclusion: { in: SUPPORTED_LANGUAGES.keys }, allow_nil: true

  accepts_nested_attributes_for :assessment_skills,
                                 allow_destroy: true,
                                 reject_if: :all_blank

  validate :skill_labels_must_be_unique

  private

  # Two skills with the same label break every interview for this assessment:
  # coverage_maps has a unique index on (session_id, skill_label). Compare the
  # in-memory skills rather than querying the DB, so duplicates arriving in the
  # same nested-attributes request are caught too. Labels match ignoring case
  # and extra spaces; skills being removed in this request don't count.
  def skill_labels_must_be_unique
    labels = assessment_skills.reject(&:marked_for_destruction?)
                              .map { |skill| skill.skill_label.to_s.squish }
                              .reject(&:blank?)
    duplicate = labels.group_by(&:downcase).values.find { |group| group.size > 1 }
    return unless duplicate

    errors.add(:base, "Skill '#{duplicate.first}' is listed more than once")
  end
end
