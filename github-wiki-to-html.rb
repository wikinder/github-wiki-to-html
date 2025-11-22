#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('lib', __dir__))

require 'github_wiki_to_html'

GithubWikiToHtml::Runner.call(ARGV)
