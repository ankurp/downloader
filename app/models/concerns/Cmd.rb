# frozen_string_literal: true

class Cmd
  attr_reader :cmd, :pid

  # Initialize a Runner object
  #
  # @param [Printer] printer
  #   the printer to use for logging
  #
  # @api private
  def initialize(cmd, opts, &block)
    @cmd = TTY::Command::Cmd.new(cmd, opts)
    @block = block
  end

  # Execute child process
  #
  # Write the input if provided to the child's stdin and read
  # the contents of both the stdout and stderr.
  #
  # If a block is provided then yield the stdout and stderr content
  # as its being read.
  #
  # @api public
  def run(&block)
    pid, _, stdout, stderr = TTY::Command::ChildProcess.spawn(@cmd)
    @pid = pid

    out_handler = ->(data) {
      @block&.call(data, nil)
    }

    err_handler = ->(data) {
      @block&.call(nil, data)
    }

    stdout_thread = read_stream(stdout, out_handler)
    stderr_thread = read_stream(stderr, err_handler)

    stdout_thread.join
    stderr_thread.join

    wait.join
    yield(@status)
  end

  def wait
    Thread.new do
      _pid, status = Process.wait2(pid)
      @status = status
    end
  end

  # Stop a process marked by pid
  #
  # @param [Integer] pid
  #
  # @api public
  def terminate
    Process.kill("SIGKILL", @pid)
  rescue
    nil
  end

  private

  # The buffer size for reading stdout and stderr
  BUFSIZE = 16 * 1024

  # Read stream and invoke handler when data becomes available
  #
  # @param [IO] stream
  #   the stream to read data from
  # @param [Proc] handler
  #   the handler to call when data becomes available
  #
  # @api private
  def read_stream(stream, handler)
    Thread.new do
      if Thread.current.respond_to?(:report_on_exception)
        Thread.current.report_on_exception = false
      end
      Thread.current[:cmd_start] = Time.now
      readers = [stream]

      while readers.any?
        ready = IO.select(readers, nil, readers, nil)
        raise TimeoutExceeded if ready.nil?

        ready[0].each do |reader|
          chunk = reader.readpartial(BUFSIZE)
          handler.call(chunk)
        rescue Errno::EAGAIN, Errno::EINTR
        rescue EOFError, Errno::EPIPE, Errno::EIO # thrown by PTY
          readers.delete(reader)
          reader.close
        end
      end
    end
  end
end
