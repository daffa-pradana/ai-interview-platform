# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Assessment, type: :model do
  before do
    @organization = Organization.create!(
      name: 'Test Org', scheme: 'test-org', identifier: 'test-org', host: 'test-org.test'
    )
  end

  describe 'validation' do
    it 'returns error when name is not given' do
      within_organization do
        subject = described_class.new(name: '', time_limit_min: 30, created_by: 1)
        expect(subject.save).to eq(false)
      end
    end

    it 'returns error when time limit is not one of the allowed options' do
      within_organization do
        subject = described_class.new(name: 'Jr. Backend Engineer', time_limit_min: 20, created_by: 1)
        expect(subject.save).to eq(false)
      end
    end

    it 'raises when created outside an organization' do
      subject = described_class.new(name: 'Jr. Backend Engineer', time_limit_min: 30, created_by: 1)
      expect { subject.save }.to raise_error(RuntimeError, /please set Current.tenant_id/)
    end

    # S3-AC1 / S3-AC2: duplicates inside the same request, matched ignoring case and extra spaces
    it 'returns error when two skills have the same label ignoring case and spaces' do
      within_organization do
        subject = described_class.new(
          name: 'Jr. Backend Engineer', time_limit_min: 30, created_by: 1,
          assessment_skills_attributes: [
            skill_attributes(skill_label: 'RESTful API Design', display_order: 0),
            skill_attributes(skill_label: ' restful  api design ', display_order: 1)
          ]
        )
        expect(subject.save).to eq(false)
        expect(subject.errors.full_messages.join).to include('RESTful API Design')
        expect(described_class.count).to eq(0)
      end
    end
  end

  describe 'Create' do
    it 'returns ok with valid inputs' do
      within_organization do
        subject = described_class.new(name: 'Jr. Backend Engineer', time_limit_min: 30, created_by: 1)
        expect(subject.save).to eq(true)
        expect(subject.tenant_id).to eq(@organization.id)
      end
    end
  end

  describe 'tenant scoping' do
    it 'returns only assessments of the current organization' do
      other_organization = Organization.create!(
        name: 'Other Org', scheme: 'other-org', identifier: 'other-org', host: 'other-org.test'
      )
      within_organization(other_organization) do
        described_class.new(name: 'Other Assessment', time_limit_min: 30, created_by: 1).save!
      end

      within_organization do
        mine = described_class.new(name: 'Jr. Backend Engineer', time_limit_min: 30, created_by: 1)
        mine.save!
        expect(described_class.all.size).to eq(1)
        expect(described_class.first).to eq(mine)
      end
    end
  end

  def skill_attributes(**overrides)
    {
      skill_label: 'Test Skill', is_custom: true, expected_level: 3, display_order: 0,
      l1_anchor: 'Level 1 behaviour', l2_anchor: 'Level 2 behaviour', l3_anchor: 'Level 3 behaviour',
      l4_anchor: 'Level 4 behaviour', l5_anchor: 'Level 5 behaviour'
    }.merge(overrides)
  end
end
