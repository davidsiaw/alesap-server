# frozen_string_literal: true

# Loads every <table>/batch-*.yml of the dump into the matching (already created) tables in
# `schema`, for TbldumpImportService. Files are parsed and COPYed by forked workers, each
# with its own DB connection; progress is logged as files finish.
#
#   TbldumpParallelLoaderService.new.call('db/tbldump', schema: 'pasela_import', workers: 16, log: log)
#   # => { 't_karaoke_master' => 508972, ... }
class TbldumpParallelLoaderService
  TABLES = TbldumpTableService::ALL

  attr_reader :file_count, :loaded, :failed

  # Returns { table => rows loaded }.
  def call(dir, schema:, workers:, log:)
    @dir = dir
    @schema = schema
    @workers = workers
    @log = log
    groups = worker_groups
    ActiveRecord::Base.connection_handler.clear_all_connections!
    reader, writer = IO.pipe
    pids = groups.map { |group| fork_worker(group, reader, writer) }
    writer.close

    @loaded = collect_counts(reader)
    @failed = pids.count { |pid| !Process.wait2(pid).last.success? }
    ActiveRecord::Base.establish_connection
    raise "#{@failed} import worker(s) failed, see output above" if @failed.positive?

    @loaded
  end

  # A worker's job: copies each [table, file] of the group into `schema` and reports
  # "table<TAB>rows" per file on `writer`. Returns the worker's exit status: 0, or 1 after
  # printing the error.
  def work(group, writer, schema)
    group.each { |table, file| writer.puts("#{table}\t#{file_service.copy(schema, table, file)}") }
    0
  rescue StandardError => e
    warn "#{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    1
  end

  private

  # Largest files first, dealt round-robin, so workers finish at about the same time.
  def worker_groups
    files = TABLES.keys.flat_map { |t| Dir[File.join(@dir, t, '*.yml')].map { |f| [t, f] } }
    @file_count = files.size
    @log.info("loading #{files.size} files with #{@workers} workers")
    groups = Array.new(@workers) { [] }
    files.sort_by { |_, f| -File.size(f) }.each_with_index { |job, i| groups[i % @workers] << job }
    groups.reject(&:empty?)
  end

  # exit! (not exit) so the child doesn't run the parent's at_exit hooks or close its
  # inherited connections.
  def fork_worker(group, reader, writer)
    fork do
      reader.close
      ActiveRecord::Base.establish_connection
      exit!(work(group, writer, @schema)) # rubocop:disable Rails/Exit
    end
  end

  def collect_counts(reader)
    progress = @log.progress(@file_count)
    reader.each_line.with_object(Hash.new(0)) do |line, loaded|
      table, count = line.chomp.split("\t")
      loaded[table] += count.to_i
      progress.tick(count.to_i)
    end
  end

  def file_service
    @file_service ||= TbldumpFileService.new
  end
end
