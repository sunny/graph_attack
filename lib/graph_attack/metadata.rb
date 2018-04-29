# Add custom field metadata
GraphQL::Field.accepts_definitions(
  rate_limit: GraphQL::Define.assign_metadata_key(:rate_limit),
)
