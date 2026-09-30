# frozen_string_literal: true

require 'puppet_litmus'
require 'spec_helper_acceptance_local' if File.file?(File.join(File.dirname(__FILE__), 'spec_helper_acceptance_local.rb'))

PuppetLitmus.configure!

# Work around a puppet_litmus 1.6.1 bug under Ruby >= 3.4.
#
# `find_targets` locates inventory targets by scanning the inventory hash's
# string form with a regex that assumes the pre-3.4 `Hash#to_s` output
# (`"uri"=>"x"`). Ruby 3.4 changed that to `"uri" => "x"` (with spaces), so the
# scan matches nothing and `apply_manifest` raises
# `Target 'litmus_localhost' not found`. Make the scan tolerant of both forms.
# The FreeBSD VM ships Ruby 3.4; the Linux jobs (Ruby 3.2) are unaffected.
module PuppetLitmus::InventoryManipulation
  def find_targets(inventory_hash, targets)
    return [targets] unless targets.nil?

    inventory_hash.to_s.scan(%r{uri"\s*=>\s*"([^"]*)"}).flatten
  end
end

RSpec.configure do |c|
  c.formatter = :documentation
  c.color     = true

  # incron ships only in EPEL on RHEL-family; the module manages no repos, so
  # enable EPEL here before any manifest runs. `before(:context)` (not
  # `before(:suite)`) runs in example-group scope where litmus's `run_shell`
  # exists; the guard no-ops on Debian/FreeBSD and stays idempotent via `rpm -q`.
  c.before(:context) do
    run_shell('if command -v dnf >/dev/null 2>&1 && ! rpm -q epel-release >/dev/null 2>&1; then dnf install -y epel-release; fi')
  end
end

# Whether the machine under test is FreeBSD.
#
# `litmus:acceptance:localhost` runs rspec on the target itself, so `uname` is
# authoritative and, unlike litmus's `fact` helper, is available at file-load
# time (i.e. in `describe`/metadata scope, where these guards are evaluated).
def freebsd_target?
  `uname -s`.strip == 'FreeBSD'
end
