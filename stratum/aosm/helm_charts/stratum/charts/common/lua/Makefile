
# The list of Lua unit test.
TESTS := \
	test_requests_have_no_mappings.lua \
	test_no_mappings.lua \
	test_string_utils.lua \
	test_mappings.lua \
	regex_tester.lua \
	unit_tests.lua \
	att_call_flow_tests.lua \
	partitioning_url_mapping_tests.lua \
	test_concat.lua \
	test_remote_partitions_unavailable.lua \
	test_local_partition_unavailable.lua \
	test_backends.lua \
	test_applet.lua \
	test_msisdn_requests.lua

.PHONY: $(TESTS) test all

$(TESTS):
	@echo "Running Lua unit test: $@"
	lua $@ -v

test: $(TESTS)


all: test
	@echo "Running the Lua unit tests"
	
clean:
	@echo "Nothing to see here..."

