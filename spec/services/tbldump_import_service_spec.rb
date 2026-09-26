# frozen_string_literal: true

require 'rails_helper'

# spec/fixtures/tbldump/import: two rows per table. Text columns carry values that would break
# a naive parser or COPY: a YAML-ambiguous scalar ('YES'), quotes, a tab, a backslash, a
# newline, and a null (song_alias of row 2).
RSpec.describe TbldumpImportService, :no_db_transaction do
  it 'loads every table into the pasela schema' do
    loaded = described_class.new.call('spec/fixtures/tbldump/import', workers: 2, logger: Logger.new(nil))

    expect(loaded).to eq(TbldumpTableService::ALL.keys.index_with(2))
    expect(TbldumpTableService::ALL.keys.map do |table|
      ActiveRecord::Base.connection.select_value("SELECT count(*) FROM pasela.#{table}")
    end).to all(eq(2))
  end

  it 'round-trips values exactly' do
    described_class.new.call('spec/fixtures/tbldump/import', workers: 2, logger: Logger.new(nil))

    rows = ActiveRecord::Base.connection.select_all(<<~SQL.squish).to_a
      SELECT song_name, song_alias, available_date FROM pasela.t_karaoke_master ORDER BY t_karaoke_master_id
    SQL
    date = Time.utc(2026, 9, 18, 3, 5, 28)
    expect(rows).to eq([
                         { 'song_name' => 'YES', 'song_alias' => 'YES', 'available_date' => date },
                         { 'song_name' => "it's \"quoted\"\tand\\slashed\nover lines", 'song_alias' => nil,
                           'available_date' => date }
                       ])
  end

  it 'replaces the previous import when run again' do
    2.times { described_class.new.call('spec/fixtures/tbldump/import', workers: 2, logger: Logger.new(nil)) }

    songs = ActiveRecord::Base.connection.select_value('SELECT count(*) FROM pasela.t_karaoke_master')
    schemas = ActiveRecord::Base.connection.select_values(
      "SELECT nspname FROM pg_namespace WHERE nspname LIKE 'pasela%'"
    )

    expect([songs, schemas]).to eq([2, ['pasela']])
  end

  it 'fails on an unexpected column and leaves the previous import in place' do
    described_class.new.call('spec/fixtures/tbldump/import', workers: 2, logger: Logger.new(nil))

    Dir.mktmpdir do |dir|
      FileUtils.cp_r('spec/fixtures/tbldump/import/.', dir)
      File.write(File.join(dir, 'mt_duet', 'batch-1.yml'), [{ 'mt_duet_id' => 9, 'bogus' => 'x' }].to_yaml)

      expect { described_class.new.call(dir, workers: 2, logger: Logger.new(nil)) }
        .to raise_error(/import worker\(s\) failed/).and output(/unexpected columns bogus/).to_stderr_from_any_process
    end
    expect(ActiveRecord::Base.connection.select_value('SELECT count(*) FROM pasela.mt_duet')).to eq(2)
  end

  it 'logs progress: loading progress and every step with its duration' do
    out = StringIO.new
    described_class.new.call('spec/fixtures/tbldump/import', workers: 2, logger: Logger.new(out))

    expect(out.string).to include(
      'loading 20 files', 'loaded 20/20 files (100%)', 'added primary keys',
      'search index: terms', 'search index: indexes', 'swapped in', 'pasela import done'
    ).and match(/added primary keys\s+\d+\.\ds/)
  end

  it 'fails before touching the database when a table folder is missing' do
    Dir.mktmpdir do |dir|
      expect { described_class.new.call(dir, workers: 2, logger: Logger.new(nil)) }
        .to raise_error(/missing table folders.*t_tieup/)
    end
    expect(ActiveRecord::Base.connection.select_value("SELECT count(*) FROM pg_namespace WHERE nspname LIKE 'pasela%'"))
      .to eq(0)
  end
end
