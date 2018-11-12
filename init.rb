Redmine::Plugin.register :redmine_group_issue do
  name 'Redmine Group Issue plugin'
  author 'Bilel Kedidi'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
end

require 'redmine_group_issue/patches/query_patch'
require 'redmine_group_issue/patches/issue_query_patch'
require 'redmine_group_issue/patches/queries_helper_patch'
