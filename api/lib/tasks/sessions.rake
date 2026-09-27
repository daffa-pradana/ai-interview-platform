# frozen_string_literal: true

namespace :sessions do
  desc 'End active sessions that are past their deadline (for sessions orphaned by a restart)'
  task end_overdue: :environment do
    SessionDeadlineWorker.end_overdue_sessions
  end
end
