# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Tenant isolation of candidate portfolios', type: :request do
  before do
    @organization = Organization.create!(
      name: 'Owner Org', scheme: 'owner-org', identifier: 'owner-org', host: 'owner-org.test'
    )
    @other_organization = Organization.create!(
      name: 'Other Org', scheme: 'other-org', identifier: 'other-org', host: 'other-org.test'
    )
    within_organization do
      assessment = Assessment.new(name: 'Jr. Backend Engineer', time_limit_min: 30, created_by: 1)
      assessment.save!
      @session = Session.new(assessment: assessment, candidate_name: 'Test Candidate A', status: 'ended')
      @session.save!
    end
    @portfolio = Portfolio.create!(session: @session, generation_status: 'complete', generated_at: Time.current)
    @skill = @portfolio.portfolio_skills.create!(
      skill_label: 'RESTful API Design', ai_level: 2, ai_confidence: 'medium', competency_summary: 'Test summary'
    )
  end

  it "does not show another organization's portfolio through the session route" do
    get_json "/api/v1/sessions/#{@session.id}/portfolio", {}, as_admin(@other_organization)

    expect(response).to have_http_status(404)
  end

  it "does not export another organization's portfolio" do
    pending 'P0: portfolios have no tenant scope; the fix needs a backfill migration (see assessment/report.md)'

    get_json "/api/v1/portfolios/#{@portfolio.id}/export", { format: 'json' }, as_admin(@other_organization)

    expect(response).to have_http_status(404)
  end

  it "does not let another organization override a candidate's skill level" do
    pending 'P0: portfolios have no tenant scope; the fix needs a backfill migration (see assessment/report.md)'

    post_json "/api/v1/portfolio_skills/#{@skill.id}/override",
              { override: { override_level: 5, assessor_notes: 'Changed by another organization' } },
              as_admin(@other_organization)

    expect(response).to have_http_status(404)
    expect(AssessorOverride.count).to eq(0)
  end
end
