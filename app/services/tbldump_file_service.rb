# frozen_string_literal: true

# One batch file of the Pasela dump (<table>/batch-*.yml), for TbldumpParallelLoaderService.
#
#   TbldumpFileService.new.copy('pasela_import', 'mt_duet', 'db/tbldump/mt_duet/batch-0.yml') # => rows copied
class TbldumpFileService
  # The file's rows. Raises if a row has a column TbldumpTableService doesn't know (the dump
  # format changed).
  def rows(file, columns)
    rows = YAML.load_file(file) || []
    unknown = rows.flat_map(&:keys).uniq - columns
    raise "#{file}: unexpected columns #{unknown.join(', ')}" if unknown.any?

    rows
  end

  # COPYs the file into <schema>.<table>. Returns the number of rows.
  def copy(schema, table, file)
    columns = TbldumpTableService::ALL.fetch(table).last.keys.map(&:to_s)
    loaded = rows(file, columns)
    pg = ActiveRecord::Base.connection.raw_connection
    pg.copy_data("COPY #{schema}.#{table} (#{columns.join(', ')}) FROM STDIN", PG::TextEncoder::CopyRow.new) do
      loaded.each { |row| pg.put_copy_data(row.values_at(*columns)) }
    end
    loaded.size
  end
end
