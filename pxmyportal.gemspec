# frozen_string_literal: true

require_relative "lib/pxmyportal/version"

Gem::Specification.new do |spec|
  spec.name = "pxmyportal"
  spec.version = PXMyPortal::VERSION
  spec.authors = ["gemmaro"]
  spec.email = ["gemmaro.dev@gmail.com"]

  spec.summary = "PXまいポータルのコマンドラインツール"
  spec.description = "このgemはPXまいポータルのコマンドラインツールpxmyportalを提供します。現時点で給与明細書のダウンロードを行えます。"
  spec.license = "GPL-3.0-or-later"

  spec.required_ruby_version = ">= 3.0.0"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }

  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri"

  spec.homepage = "https://github.com/gemmaro/pxmyportal"
  spec.metadata = {
    'rubygems_mfa_required' => 'true',
    'bug_tracker_uri' => "#{spec.homepage}/issues",
    'changelog_uri' => "#{spec.homepage}/blob/main/CHANGELOG.md",
    'documentation_uri' => 'https://rubydoc.info/gems/pxmyportal',
    'homepage_uri' => spec.homepage,
    'source_code_uri' => spec.homepage,
    'wiki_uri' => "#{spec.homepage}/wiki"
  }
end
