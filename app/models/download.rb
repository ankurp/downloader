class Download < ApplicationRecord
  enum status: {failure: -1, success: 0, not_started: 1, running: 2, killed: 3}

  has_many :outputs, dependent: :destroy

  validates :text, presence: true

  broadcasts_to ->(download) { [:downloads, download] }
  after_create_commit ->(download) { broadcast_prepend_to :downloads, partial: "downloads/download_table" }
  after_update_commit ->(download) { broadcast_replace_to :downloads, partial: "downloads/download_table" }
  after_destroy_commit ->(download) { broadcast_remove_to :downloads }

  after_create :perform_async

  def perform_async
    runner = DownloadRunnerJob.perform_later(self)
    update(job_id: runner.job_id)
  end

  def kill!
    DownloadRunnerJob.cancel!(job_id)
  end

  def completed?
    success? || failure?
  end
end
