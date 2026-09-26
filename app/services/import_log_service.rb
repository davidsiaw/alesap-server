# frozen_string_literal: true

# Progress output for `rake pasela:import` (download, load, search index): each step with how
# long it took, and a running count while files load.
class ImportLogService
  def initialize(logger)
    @logger = logger
  end

  delegate :info, to: :@logger

  # Runs the block and logs the label with its duration. Returns the block's result.
  def step(label)
    started = now
    result = yield
    info(format('%-40<label>s %6.1<secs>fs', label: label, secs: now - started))
    result
  end

  # Counts finished items; logs at every 10% and at the end.
  class Progress
    def initialize(log, total, started)
      @log = log
      @total = total
      @started = started
      @done = 0
      @rows = 0
      @next_percent = 10
    end

    def tick(rows)
      @done += 1
      @rows += rows
      percent = @done * 100 / @total
      return if percent < @next_percent && @done < @total

      @log.info(format('loaded %<done>d/%<total>d files (%<pct>d%%), %<rows>d rows, %<secs>.1fs',
                       done: @done, total: @total, pct: percent, rows: @rows, secs: @log.now - @started))
      @next_percent = ((percent / 10) + 1) * 10
    end
  end

  def progress(total)
    Progress.new(self, total, now)
  end

  def now
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end
