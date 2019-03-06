Redmine::Plugin.register :redmine_group_issue do
  name 'Redmine Group Issue plugin'
  author 'Bilel Kedidi'
  description 'This is a plugin for Redmine'
  version '1.0.2'
  url 'https://www.github.com/bilel-kedidi/redmine_group_issue'
  author_url 'https://www.github.com/bilel-kedidi'
end

require 'redmine_group_issue/patches/query_patch'
require 'redmine_group_issue/patches/issue_query_patch'
require 'redmine_group_issue/patches/queries_helper_patch'
