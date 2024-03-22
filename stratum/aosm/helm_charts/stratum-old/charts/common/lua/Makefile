all:
	@echo "Running the Lua unit tests"
	lua test_requests_have_no_mappings.lua -v
	lua test_no_mappings.lua -v
	lua test_string_utils.lua -v
	lua test_mappings.lua -v
	lua regex_tester.lua -v
	lua unit_tests.lua -v
	lua att_call_flow_tests.lua -v
	lua partitioning_url_mapping_tests.lua -v
	lua test_concat.lua -v
	lua test_remote_partitions_unavailable.lua -v
	lua test_local_partition_unavailable.lua -v
	lua test_backends.lua -v
	lua test_response.lua -v

clean:
	@echo "Nothing to see here..."
