# frozen_string_literal: true

# Loads the Pasela table dump (db/tbldump layout: <table>/batch-*.yml) into raw tables
# in the `pasela` Postgres schema, mirroring the dump 1:1. See docs/import.md.
#
# Files are parsed and COPYed in parallel (TbldumpParallelLoaderService). Everything is loaded into
# a scratch schema first (TbldumpScratchSchemaService) and swapped in at the end, so a failed
# import leaves the previous `pasela` schema untouched. The search index
# (PaselaSearchIndexBuilderService) is built in the scratch schema too, so it's always in sync
# with the raw tables.
#
#   TbldumpImportService.new.call('db/tbldump', workers: 16, dictionary: {}, logger: Logger.new($stdout))
#   # => { 't_karaoke_master' => 508972, ... }
class TbldumpImportService
  SCHEMA = 'pasela'
  SCRATCH_SCHEMA = 'pasela_import'

  attr_reader :loaded, :counts

  # dictionary: see PaselaSearchIndexBuilderService
  def call(dir, workers: 16, dictionary: {}, logger: Logger.new($stdout))
    @dir = dir
    @workers = workers
    @dictionary = dictionary
    @log = ImportLogService.new(logger)
    missing = scratch.missing_tables(@dir)
    raise "missing table folders in #{@dir}: #{missing.join(', ')}" if missing.any?

    @log.step('pasela import done') { import }
  end

  private

  def import
    @log.step('created scratch tables') { scratch.create_tables }
    @loaded = @log.step('loaded all files') { load_files }
    @log.step('added primary keys') { scratch.add_primary_keys }
    @counts = @log.step('verified row counts') { scratch.verify_counts(@loaded) }
    @counts.each { |table, rows| @log.info(format('%-24<t>s %<n>9d rows', t: table, n: rows)) }
    PaselaSearchIndexBuilderService.new.call(SCRATCH_SCHEMA, dictionary: @dictionary, log: @log)
    @log.step('swapped in the new data') { scratch.swap_in }
    @loaded
  end

  def load_files
    TbldumpParallelLoaderService.new.call(@dir, schema: SCRATCH_SCHEMA, workers: @workers, log: @log)
  end

  def scratch
    @scratch ||= TbldumpScratchSchemaService.new(scratch: SCRATCH_SCHEMA, live: SCHEMA)
  end
end
