require "async"

class DownloadRunnerJob < ApplicationJob
  def perform(download)
    puts "wget #{download.text}"
    @cmd = Cmd.new("wget -q --show-progress -P #{STORAGE_FOLDER} #{download.text}", pty: true) do |out, err|
      args = {
        text: (out.present? ? out.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?") : err.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")) || "",
        type: out.present? ? :out : :err
      }

      if download.outputs.size == 0
        download.outputs.create(args)
      else
        download.outputs.last.update(args)
      end
    rescue TTY::Command::ExitError => err
      download.outputs.create(
        text: err.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?"),
        type: :err
      )
    end

    Async::Reactor.run do
      Async do
        download.update(status: :running)
        while download.running?
          sleep 1.seconds
          break if DownloadRunnerJob.cancelled?(download.job_id)
        end
        @cmd.terminate
      end

      @cmd.run do |status|
        if status.termsig.present?
          download.update(status: :killed)
          download.outputs.create(text: "Killed", type: :err)
        else
          cmd_status = status.exitstatus.zero? ? :success : :failure
          download.update(status: cmd_status)
          download.outputs.create(text: cmd_status == :success ? "Done" : "Failed", type: cmd_status == :success ? :out : :err)
        end
      end
    end
  end

  def check_for_cancellation(download)
  end

  def self.cancelled?(jid)
    Sidekiq.redis { |c| c.exists?("cancelled-#{jid}") }
  end

  def self.cancel!(jid)
    Sidekiq.redis { |c| c.setex("cancelled-#{jid}", 1.minute, 1) }
  end
end
