# frozen_string_literal: true

# Downloads a .tar.gz of the Pasela table dump and extracts it, for TbldumpImportService.
#
#   download = TbldumpDownloadService.new
#   download.call('http://alesap-tbldump:8080/tbldump.tar.gz', 'tmp/tbldump', logger: logger)
#   # => "tmp/tbldump" (or "tmp/tbldump/<top-level folder>")
class TbldumpDownloadService
  attr_reader :tarball, :dir

  # Extracts into dest (wiped first). Returns the directory that contains the table folders.
  def call(url, dest, logger: Logger.new(nil))
    @url = url
    @dest = dest
    @tarball = File.join(dest, 'tbldump.tar.gz')
    @log = ImportLogService.new(logger)
    FileUtils.rm_rf(dest)
    FileUtils.mkdir_p(dest)
    @log.info("downloading #{url}")
    @log.step('downloaded') { download }
    @log.info(format('tarball is %.1f MB', File.size(@tarball) / 1_048_576.0))
    @log.step('extracted') { extract }
    FileUtils.rm_f(@tarball)
    @dir = table_dir(dest)
  end

  # The directory holding the table folders: `dir` itself, or its one top-level folder.
  def table_dir(dir)
    marker = Dir.glob(File.join(dir, '{,*/}t_karaoke_master')).first
    raise "no t_karaoke_master folder found in #{dir}" unless marker

    File.dirname(marker)
  end

  private

  # -sS: no progress meter in the logs, but still print errors. Retry for ~1 min, also on
  # "connection refused": in the stack the tbldump server starts alongside the app.
  def download
    system('curl', '-fsSL', '--retry', '12', '--retry-delay', '5', '--retry-connrefused',
           '-o', @tarball, @url, exception: true)
  end

  def extract
    system('tar', 'xzf', @tarball, '-C', @dest, exception: true)
  end
end
