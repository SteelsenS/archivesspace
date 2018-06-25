class DateSubreport < AbstractSubreport

	register_subreport('date', ['accession', 'deaccession',
		'archival_object', 'resource', 'event', 'digital_object',
		'digital_object_component', 'related_agents_rlshp', 'agent_person',
		'agent_family', 'agent_corporate_entity', 'agent_software',
		'name_person', 'name_family', 'name_corporate_entity',
		'name_software'])

	def initialize(parent_custom_report, id)
		super(parent_custom_report)

		@id_type = parent_custom_report.record_type
		@id = id
	end

	def query
		db.fetch(query_string)
	end

	def query_string
		"select
			date_type_id as date_type,
			label_id as label,
			certainty_id as certainty,
			expression,
			begin,
			end,
			era_id as era,
			calendar_id as calendar
		from date
		where #{@id_type}_id = #{@id}"
	end

	def fix_row(row)
		ReportUtils.get_enum_values(row, [:date_type, :label, :certainty,
			:era, :calendar])
	end

	def self.field_name
		'date'
	end
end