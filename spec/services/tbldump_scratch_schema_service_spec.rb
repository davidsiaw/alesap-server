# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TbldumpScratchSchemaService, :no_db_transaction do
  describe '#missing_tables' do
    it 'lists the table folders a dump directory lacks' do
      scratch = described_class.new(scratch: 'pasela_import', live: 'pasela')

      expect([scratch.missing_tables('spec/fixtures/tbldump/import'), scratch.missing_tables('spec/fixtures').size])
        .to eq([[], TbldumpTableService::ALL.size])
    end
  end

  describe '#create_tables' do
    it 'creates one empty table per dump table in a fresh scratch schema' do
      described_class.new(scratch: 'pasela_import', live: 'pasela').create_tables

      expect(ActiveRecord::Base.connection.select_values(
               "SELECT table_name FROM information_schema.tables WHERE table_schema = 'pasela_import'"
             )).to match_array(TbldumpTableService::ALL.keys)
    end
  end

  describe '#add_primary_keys' do
    it 'adds the primary keys, and fails on duplicate ids' do
      scratch = described_class.new(scratch: 'pasela_import', live: 'pasela')
      scratch.create_tables
      ActiveRecord::Base.connection.execute("INSERT INTO pasela_import.mt_duet VALUES (1, 'a'), (1, 'b')")

      expect { scratch.add_primary_keys }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'skips tables without one' do
      scratch = described_class.new(scratch: 'pasela_import', live: 'pasela')
      scratch.create_tables
      scratch.add_primary_keys

      keyed = ActiveRecord::Base.connection.select_values(<<~SQL.squish)
        SELECT tc.table_name FROM information_schema.table_constraints tc
        WHERE tc.table_schema = 'pasela_import' AND tc.constraint_type = 'PRIMARY KEY'
      SQL
      expect(keyed).to match_array(TbldumpTableService::ALL.select { |_, (pk, _)| pk }.keys)
    end
  end

  describe '#verify_counts' do
    it 'returns the row counts, and raises when they differ from what was parsed' do
      scratch = described_class.new(scratch: 'pasela_import', live: 'pasela')
      scratch.create_tables
      ActiveRecord::Base.connection.execute("INSERT INTO pasela_import.mt_duet VALUES (1, 'a')")
      parsed = TbldumpTableService::ALL.keys.index_with(0).merge('mt_duet' => 1)

      expect(scratch.verify_counts(parsed)).to eq(parsed)
      expect { scratch.verify_counts(parsed.merge('mt_duet' => 2)) }
        .to raise_error('mt_duet: parsed 2 rows but table has 1')
    end
  end

  describe '#swap_in' do
    it 'replaces the live schema with the scratch one' do
      ActiveRecord::Base.connection.execute('CREATE SCHEMA pasela; CREATE TABLE pasela.old_marker (x int)')
      described_class.new(scratch: 'pasela_import', live: 'pasela').tap(&:create_tables).swap_in

      tables = ActiveRecord::Base.connection.select_values(
        "SELECT table_schema || '.' || table_name FROM information_schema.tables WHERE table_schema LIKE 'pasela%'"
      )
      expect([tables.include?('pasela.old_marker'), tables.include?('pasela.mt_duet'), tables.grep(/pasela_import/)])
        .to eq([false, true, []])
    end
  end
end
