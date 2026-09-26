# frozen_string_literal: true

# The scratch schema TbldumpImportService loads into before swapping it in as the live one.
#
#   scratch = TbldumpScratchSchemaService.new(scratch: 'pasela_import', live: 'pasela')
#   scratch.create_tables; ...load...; scratch.add_primary_keys; scratch.verify_counts(loaded); scratch.swap_in
class TbldumpScratchSchemaService
  TABLES = TbldumpTableService::ALL

  def initialize(scratch:, live:)
    @scratch = scratch
    @live = live
  end

  # Table folders the dump in `dir` is missing.
  def missing_tables(dir)
    TABLES.keys.reject { |table| Dir.exist?(File.join(dir, table)) }
  end

  # (Re)creates the scratch schema with one empty table per dump table.
  def create_tables
    conn.execute("DROP SCHEMA IF EXISTS #{@scratch} CASCADE; CREATE SCHEMA #{@scratch}")
    TABLES.each do |table, (_pk, columns)|
      conn.execute("CREATE TABLE #{@scratch}.#{table} (#{columns.map { |c, type| "#{c} #{type}" }.join(', ')})")
    end
  end

  # Primary keys go on after the load: faster, and they double as a uniqueness check.
  def add_primary_keys
    TABLES.each do |table, (pk, _columns)|
      conn.execute("ALTER TABLE #{@scratch}.#{table} ADD PRIMARY KEY (#{pk})") if pk
      conn.execute("ANALYZE #{@scratch}.#{table}")
    end
  end

  # Checks each table has as many rows as were parsed ({ table => rows }). Returns the counts.
  def verify_counts(loaded)
    TABLES.keys.to_h do |table|
      in_db = conn.select_value("SELECT count(*) FROM #{@scratch}.#{table}").to_i
      raise "#{table}: parsed #{loaded[table]} rows but table has #{in_db}" if in_db != loaded[table]

      [table, in_db]
    end
  end

  # One multi-statement query runs as a single transaction, so the swap is atomic.
  def swap_in
    conn.execute("DROP SCHEMA IF EXISTS #{@live} CASCADE; ALTER SCHEMA #{@scratch} RENAME TO #{@live}")
  end

  private

  def conn
    ActiveRecord::Base.connection
  end
end
