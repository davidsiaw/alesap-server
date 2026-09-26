# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TbldumpFileService do
  describe '#rows' do
    it 'returns the rows of a batch file' do
      rows = described_class.new.rows('spec/fixtures/tbldump/import/mt_duet/batch-0.yml', %w[mt_duet_id duet_type])

      expect(rows).to eq([{ 'mt_duet_id' => 1, 'duet_type' => 'YES' },
                          { 'mt_duet_id' => 2, 'duet_type' => "it's \"quoted\"\tand\\slashed\nover lines" }])
    end

    it 'raises on a column the table definition does not know' do
      expect { described_class.new.rows('spec/fixtures/tbldump/import/mt_duet/batch-0.yml', %w[mt_duet_id]) }
        .to raise_error(/unexpected columns duet_type/)
    end
  end

  describe '#copy', :no_db_transaction do
    it 'copies the file into the table and returns the row count' do
      TbldumpScratchSchemaService.new(scratch: 'pasela_import', live: 'pasela').create_tables

      copied = described_class.new.copy('pasela_import', 'mt_duet', 'spec/fixtures/tbldump/import/mt_duet/batch-0.yml')

      expect([copied, ActiveRecord::Base.connection.select_values('SELECT mt_duet_id FROM pasela_import.mt_duet')])
        .to eq([2, [1, 2]])
    end
  end
end
