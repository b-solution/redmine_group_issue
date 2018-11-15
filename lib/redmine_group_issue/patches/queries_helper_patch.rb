module RedmineGroupIssue
  module Patches
    module QueriesHelperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method_chain :group_by_column_select_tag, :group
          alias_method_chain :grouped_query_results, :group
        end
      end
    end

    module InstanceMethods
      def group_by_column_select_tag_with_group(query)
        options = [[]] + query.groupable_columns.collect {|c| [c.caption, c.name.to_s]}
        if query.is_a? IssueQuery
          [
              select_tag('group_by[]', options_for_select(options, @query.group_by.to_s.scan(/\w+/)[0])),
              select_tag('group_by[]', options_for_select(options, @query.group_by.to_s.scan(/\w+/)[1])),
              select_tag('group_by[]', options_for_select(options, @query.group_by.to_s.scan(/\w+/)[2]))
          ].join('<br/>').html_safe

        else
          group_by_column_select_tag_without_group(query)
        end
      end

      def grouped_query_results_with_group(items, query, &block)
        if query.is_a? IssueQuery
          result_count_by_group = query.result_count_by_group
          previous_group, first = false, true
          totals_by_group = query.totalable_columns.inject({}) do |h, column|
            h[column] = query.total_by_group_for(column)
            h
          end
          items.each do |item|
            group_name = group_count = nil
            if query.grouped?
              group = query.group_by_column.map{|c| c.value(item)}
              if first || group != previous_group
                if group.blank? && group != false
                  group_name = "(#{l(:label_blank_value)})"
                else
                  group_name = group.is_a?(Array) ? group.map{|g| format_object(g) } : format_object(group)
                end
                group_name ||= ""
                group_count = result_count_by_group ? result_count_by_group[group.count > 1 ? group : group.first] : nil
                group_totals = totals_by_group.map {|column, t| total_tag(column, t[group] || 0)}.join(" ").html_safe
              end
            end
            yield item, group_name, group_count, group_totals
            previous_group, first = group, false
          end
        else
          grouped_query_results_without_group(items, query, &block)
        end

      end
    end
  end
end

unless QueriesHelper.included_modules.include?( RedmineGroupIssue::Patches::QueriesHelperPatch)
  QueriesHelper.send(:include,  RedmineGroupIssue::Patches::QueriesHelperPatch)
end