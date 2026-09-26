# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  before do
    @organization = Organization.create!(
      name: 'Test Org', scheme: 'test-org', identifier: 'test-org', host: 'test-org.test'
    )
    within_organization do
      @assessment = Assessment.new(name: 'Jr. Backend Engineer', time_limit_min: 30, created_by: 1)
      @assessment.save!
      @session = Session.new(assessment: @assessment, candidate_name: 'Test Candidate A')
      @session.save!
    end
  end

  describe 'GET /api/v1/assessments/:id/sessions' do
    it 'returns the failure code and the assessor message of a failed session' do
      @session.record_failure!('assessment_invalid', 'duplicate skills')

      get_json "/api/v1/assessments/#{@assessment.id}/sessions", {}, as_admin(@organization)

      expect(response).to have_http_status(200)
      session = response_body['sessions'].first
      expect(session['failure_code']).to eq('assessment_invalid')
      expect(session['failure_message']).to eq('Assessment needs fixing (duplicate skills).')
    end

    it 'returns no failure for a session that has not failed' do
      get_json "/api/v1/assessments/#{@assessment.id}/sessions", {}, as_admin(@organization)

      session = response_body['sessions'].first
      expect(session).to include('failure_code' => nil, 'failure_message' => nil)
    end

    it "does not return another organization's sessions" do
      other_organization = Organization.create!(
        name: 'Other Org', scheme: 'other-org', identifier: 'other-org', host: 'other-org.test'
      )

      get_json "/api/v1/assessments/#{@assessment.id}/sessions", {}, as_admin(other_organization)

      expect(response).to have_http_status(404)
    end
  end
end
