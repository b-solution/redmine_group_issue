
module RedmineGroupIssue::Patches
  module IssueQueryPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        def base_scope
          Issue.visible.joins(:status, :project).where(statement)
        end

        def group_by_sort_order
          if columns = group_by_column
            columns.map{ |column|
              order = (sort_criteria.order_for(column.name) || column.default_order || 'asc').try(:upcase)
              Array(column.sortable).map {|s| "#{s} #{order}"}
            }
          end
        end

        # Returns true if the query is a grouped query
        def grouped?
          !group_by_column.blank?
        end

        def group_by_column
          # groupable_columns.select {|c| c.groupable && c.name.to_s.in?( JSON.parse(group_by || '[]'))}
          group_by.to_s.scan(/\w+/).map(&:presence).map{|gc|  groupable_columns.detect {|c| c.groupable && c.name.to_s == gc }}.compact
        end

        def group_by_statement
          Array.wrap(group_by_column).map{|c| c.try(:groupable)}.compact
        end


        def base_group_scope
          base_scope.
              joins(joins_for_order_statement(group_by_statement)).
              group(group_by_column.map(&:sortable))
        end

        def joins_for_order_statement(order_options)
          joins = [super]

          if order_options
            if order_options.include?('authors')  || order_options.include?('author')
              joins << "LEFT OUTER JOIN #{User.table_name} authors ON authors.id = #{queried_table_name}.author_id"
            end
            if order_options.include?('users') || order_options.include?('user')  || order_options.include?('assigned_to')
              joins << "LEFT OUTER JOIN #{User.table_name} ON #{User.table_name}.id = #{queried_table_name}.assigned_to_id"
            end
            if order_options.include?('last_journal_user')  # || order_options.include?('category')
              joins << "LEFT OUTER JOIN #{Journal.table_name} ON #{Journal.table_name}.id = (SELECT MAX(#{Journal.table_name}.id) FROM #{Journal.table_name}" +
                  " WHERE #{Journal.table_name}.journalized_type='Issue' AND #{Journal.table_name}.journalized_id=#{Issue.table_name}.id AND #{Journal.visible_notes_condition(User.current, :skip_pre_condition => true)})" +
                  " LEFT OUTER JOIN #{User.table_name} last_journal_user ON last_journal_user.id = #{Journal.table_name}.user_id";
            end
            if order_options.include?('versions') || order_options.include?('fixed_version')
              joins << "LEFT OUTER JOIN #{Version.table_name} ON #{Version.table_name}.id = #{queried_table_name}.fixed_version_id"
            end
            if order_options.include?('issue_categories') || order_options.include?('category')
              joins << "LEFT OUTER JOIN #{IssueCategory.table_name} ON #{IssueCategory.table_name}.id = #{queried_table_name}.category_id"
            end
            if order_options.include?('trackers') || order_options.include?('tracker')
              joins << "LEFT OUTER JOIN #{Tracker.table_name} ON #{Tracker.table_name}.id = #{queried_table_name}.tracker_id"
            end
            if order_options.include?('enumerations')  || order_options.include?('priority')
              joins << "LEFT OUTER JOIN #{IssuePriority.table_name} ON #{IssuePriority.table_name}.id = #{queried_table_name}.priority_id"
            end
          end

          joins.any? ? joins.join(' ') : nil
        end
      end
    end

    module InstanceMethods



    end
  end
end

unless IssueQuery.included_modules.include?( RedmineGroupIssue::Patches::IssueQueryPatch)
  IssueQuery.send(:include,  RedmineGroupIssue::Patches::IssueQueryPatch)
end