# frozen_string_literal: true

require "redmine_ai_helper/base_tools"

module RedmineAiHelper
  module Tools
    class SemanticSearchTools < RedmineAiHelper::BaseTools
      define_function :semantic_search_issues,
        description: "Find issues semantically similar to the query (meaning-based, not keyword). Use when the user asks for related/similar issues or describes a problem in their own words." do
        property :query, type: "string", description: "Natural-language query or problem description.", required: true
        property :k, type: "integer", description: "Max number of issues to return (default 10, max 50).", required: false
      end

      def semantic_search_issues(query:, k: 3, **extra)
        raise "query must not be blank" if query.to_s.strip.empty?
        k = k.to_i.clamp(1, 50)

        request = FullTextSearch::Request.new(
          q: query,
          semantic: "1",
          scope: "all",
          attachments: "0",
          user: User.current,
          limit: k,
        )
        Redmine::Search.available_search_types.each do |type|
          request.public_send("#{type}=", type == :issues ? "1" : "0")
        end

        FullTextSearch::SemanticSearcher.new(request).search.records.filter_map do |target|
          issue = target.source_record
          {
            id: issue.id,
            subject: issue.subject,
            project: issue.project.name,
            status: issue.status.name,
            url: "/issues/#{issue.id}",
          }
        end
      end
    end
  end
end
