# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TbldumpParallelLoaderService, :no_db_transaction do
  describe '#work' do
    it 'copies each file and reports "table<TAB>rows" per file, returning exit status 0' do
      TbldumpScratchSchemaService.new(scratch: 'pasela_import', live: 'pasela').create_tables
      writer = StringIO.new
      group = [%w[mt_duet spec/fixtures/tbldump/import/mt_duet/batch-0.yml],
               %w[mt_gender spec/fixtures/tbldump/import/mt_gender/batch-0.yml]]

      status = described_class.new.work(group, writer, 'pasela_import')

      expect([status, writer.string]).to eq([0, "mt_duet\t2\nmt_gender\t2\n"])
    end

    it 'returns exit status 1 and prints the error when a file fails' do
      writer = StringIO.new

      expect { expect(described_class.new.work([%w[mt_duet /nonexistent.yml]], writer, 'pasela_import')).to eq(1) }
        .to output(/Errno::ENOENT/).to_stderr
    end
  end

  describe '#call' do
    it 'loads every file with forked workers and returns the rows per table' do
      TbldumpScratchSchemaService.new(scratch: 'pasela_import', live: 'pasela').create_tables
      loader = described_class.new

      loaded = loader.call('spec/fixtures/tbldump/import', schema: 'pasela_import', workers: 3,
                                                           log: ImportLogService.new(Logger.new(nil)))

      expect([loaded, loader.file_count, loader.failed]).to eq([TbldumpTableService::ALL.keys.index_with(2), 20, 0])
    end
  end
end
