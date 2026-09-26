# frozen_string_literal: true

namespace :pasela do
  desc 'Load the Pasela table dump into the `pasela` schema and build the search index. ' \
       'TBLDUMP_URL=<.tar.gz url> downloads it first; otherwise reads TBLDUMP_DIR (default db/tbldump). ' \
       'TBLDUMP_DICTIONARY=<yml> name dictionary (default db/data/jpn.yml). WORKERS=n (default 16).'
  task import: :environment do
    logger = Logger.new($stdout, progname: 'pasela import')
    url = ENV.fetch('TBLDUMP_URL', nil).presence
    download_dir = Rails.root.join('tmp/tbldump').to_s if url
    local_dir = ENV.fetch('TBLDUMP_DIR', Rails.root.join('db/tbldump').to_s)
    dir = url ? TbldumpDownloadService.new.call(url, download_dir, logger: logger) : local_dir

    dictionary_path = ENV.fetch('TBLDUMP_DICTIONARY', Rails.root.join('db/data/jpn.yml').to_s)
    dictionary = File.exist?(dictionary_path) ? YAML.load_file(dictionary_path) : {}
    warn "WARNING: no name dictionary at #{dictionary_path}; English names come from Pasela only" if dictionary.empty?

    TbldumpImportService.new.call(dir, workers: ENV.fetch('WORKERS', 16).to_i, dictionary: dictionary, logger: logger)
  ensure
    # The extracted dump is ~3 GB; don't leave it behind on every boot.
    FileUtils.rm_rf(download_dir) if download_dir
  end

  desc 'Check that the songs in config/search_smoke.yml can be found. Run after pasela:import.'
  task smoke: :environment do
    abort 'search smoke checks failed' if SearchSmokeCheckService.new.call.any?
  end
end
