# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TbldumpDownloadService do
  describe '#table_dir' do
    it 'finds the table folders at the root or inside one top-level folder' do
      dirs = %w[spec/fixtures/tbldump/import spec/fixtures/tbldump].map { |dir| described_class.new.table_dir(dir) }

      expect(dirs).to eq(['spec/fixtures/tbldump/import', 'spec/fixtures/tbldump/api'])
    end

    it 'raises when there are no table folders' do
      expect { described_class.new.table_dir('spec/fixtures/tbldump/import/mt_duet') }
        .to raise_error(/no t_karaoke_master folder found/)
    end
  end

  describe '#call' do
    it 'downloads (here from a file:// URL), extracts, removes the tarball and returns the table folder' do
      Dir.mktmpdir do |tmp|
        system('tar', 'czf', "#{tmp}/tbldump.tar.gz", '-C', 'spec/fixtures/tbldump', 'import', exception: true)
        download = described_class.new

        dir = download.call("file://#{tmp}/tbldump.tar.gz", "#{tmp}/out")

        expect([dir, File.exist?(download.tarball), Dir.exist?("#{dir}/t_karaoke_master")])
          .to eq(["#{tmp}/out/import", false, true])
      end
    end
  end
end
