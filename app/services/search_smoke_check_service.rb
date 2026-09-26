# frozen_string_literal: true

# Runs the real-data search checks in config/search_smoke.yml (see `rake pasela:smoke`).
# A check passes when the first page of results for `query` has a song whose name
# contains `song` and whose artist contains `artist`, case-insensitively. `constraint`
# (all/title/artist/tags) defaults to all.
#
#   SearchSmokeCheckService.new.call # => failed checks (prints PASS/FAIL per check)
class SearchSmokeCheckService
  attr_reader :checks, :failures

  def call(path = Rails.root.join('config/search_smoke.yml'), out: $stdout)
    @checks = YAML.load_file(path)
    @failures = @checks.reject do |check|
      results = results_for(check)
      found = found?(check, results)
      out.puts report(check, found, results)
      found
    end
    out.puts "#{@checks.size - @failures.size} of #{@checks.size} search smoke checks passed"
    @failures
  end

  # The first page of search results for the check.
  def results_for(check)
    SearchService.new.call(check['query'], 0, constraint: check.fetch('constraint', 'all'))[:results].first
  end

  def found?(check, results)
    results.any? { |r| contains?(r[:song], check['song']) && contains?(r[:artist], check['artist']) }
  end

  # PASS/FAIL line; a failure also shows the top 3 results.
  def report(check, found, results)
    line = "#{found ? 'PASS' : 'FAIL'}  #{check['query'].inspect} -> #{check['song']} / #{check['artist']}"
    return line if found

    "#{line}\n      got: #{results.first(3).map { |r| "#{r[:song]} / #{r[:artist]}" }.join(' | ')}"
  end

  private

  def contains?(value, expected)
    value.to_s.downcase.include?(expected.downcase)
  end
end
