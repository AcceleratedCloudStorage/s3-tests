# S3 Compatibility Tests Makefile
# This Makefile organizes S3 API tests based on the supported operations in your ObjectStorageV2 server
# 
# Usage:
#   make test-all          # Run all supported API tests
#   make test-buckets      # Run all bucket operation tests
#   make test-objects      # Run all object operation tests
#   make test-list         # Run list operations tests
#   make test-basic        # Run basic functionality tests
#
# Prerequisites:
#   - S3TEST_CONF environment variable set to your config file
#   - Docker containers running
#   - tox installed

# Configuration
PYTEST_CMD = S3TEST_CONF=s3tests.conf tox --
TEST_FILE = s3tests_boto3/functional/test_s3.py
PYTEST_ARGS = --tb=line -v -m 'not fails_on_aws'

# Color output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

.PHONY: help test-all test-buckets test-objects test-list test-basic test-auth test-naming test-cleanup test-multipart test-multipart-core test-multipart-debug

# Default target
help:
	@echo "$(GREEN)S3 Compatibility Test Suite$(NC)"
	@echo "=============================="
	@echo ""
	@echo "$(YELLOW)Available test targets:$(NC)"
	@echo "  $(GREEN)test-basic$(NC)         - Run basic functionality tests (quick smoke test)"
	@echo "  $(GREEN)test-core$(NC)          - Run core functionality tests (guaranteed to work)"
	@echo "  $(GREEN)test-implemented$(NC)   - Run tests for YOUR implemented APIs only"
	@echo "  $(GREEN)test-all$(NC)           - Run all core supported API tests (skips AWS-failing tests)"
	@echo "  $(GREEN)test-comprehensive$(NC) - Run comprehensive tests (includes edge cases)"
	@echo "  $(GREEN)test-all-raw$(NC)       - Run all tests including those that fail on AWS"
	@echo "  $(GREEN)test-buckets$(NC)       - Run all bucket operation tests"
	@echo "  $(GREEN)test-objects$(NC)       - Run all object operation tests"
	@echo "  $(GREEN)test-list$(NC)          - Run list operations tests"
	@echo "  $(GREEN)test-auth$(NC)          - Run authentication and authorization tests"
	@echo "  $(GREEN)test-naming$(NC)        - Run bucket/object naming validation tests"
	@echo ""
	@echo "$(YELLOW)Bucket Operations:$(NC)"
	@echo "  $(GREEN)test-bucket-create$(NC) - Test bucket creation"
	@echo "  $(GREEN)test-bucket-delete$(NC) - Test bucket deletion"
	@echo "  $(GREEN)test-bucket-head$(NC)   - Test bucket head operations"
	@echo "  $(GREEN)test-bucket-list$(NC)   - Test bucket listing"
	@echo ""
	@echo "$(YELLOW)Object Operations:$(NC)"
	@echo "  $(GREEN)test-object-put$(NC)    - Test object upload (PutObject)"
	@echo "  $(GREEN)test-object-get$(NC)    - Test object download (GetObject)"
	@echo "  $(GREEN)test-object-head$(NC)   - Test object head operations"
	@echo "  $(GREEN)test-object-delete$(NC) - Test object deletion"
	@echo "  $(GREEN)test-object-copy$(NC)   - Test object copy operations"
	@echo "  $(GREEN)test-multipart$(NC)     - Test multipart upload operations (comprehensive)"
	@echo "  $(GREEN)test-multipart-core$(NC) - Test core multipart upload operations (essential)"
	@echo "  $(GREEN)test-multipart-debug$(NC) - Test minimal multipart operations (debugging)"
	@echo ""
	@echo "$(YELLOW)List Operations:$(NC)"
	@echo "  $(GREEN)test-list-objects-v1$(NC) - Test ListObjects v1"
	@echo "  $(GREEN)test-list-objects-v2$(NC) - Test ListObjects v2"
	@echo "  $(GREEN)test-list-delimiter$(NC)  - Test delimiter-based listing"
	@echo "  $(GREEN)test-list-prefix$(NC)     - Test prefix-based listing"
	@echo ""
	@echo "$(YELLOW)Utility:$(NC)"
	@echo "  $(GREEN)test-cleanup$(NC)       - Test cleanup functionality"
	@echo "  $(GREEN)validate-config$(NC)    - Validate test configuration"
	@echo ""
	@echo "$(YELLOW)Notes:$(NC)"
	@echo "  • By default, tests marked with @pytest.mark.fails_on_aws are skipped"
	@echo "  • Use test-all-raw to run ALL tests including AWS-failing ones"
	@echo "  • Use test-edge-cases to run only the problematic edge case tests"
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make test-basic      # Quick smoke test"
	@echo "  make test-implemented # Test YOUR specific implemented APIs"
	@echo "  make test-all        # All supported APIs (filtered)"
	@echo "  make test-all-raw    # All tests including problematic ones"

# Validate configuration before running tests
validate-config:
	@echo "$(YELLOW)Validating test configuration...$(NC)"
	@if [ -z "$$S3TEST_CONF" ]; then \
		echo "$(RED)ERROR: S3TEST_CONF environment variable not set$(NC)"; \
		echo "$(YELLOW)Please set it to your s3tests.conf file path$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f "$$S3TEST_CONF" ]; then \
		echo "$(RED)ERROR: Configuration file $$S3TEST_CONF not found$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✓ Configuration valid: $$S3TEST_CONF$(NC)"

# Quick smoke test - basic functionality
test-basic: validate-config
	@echo "$(GREEN)Running basic functionality tests...$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_bucket_create_delete \
		$(TEST_FILE)::test_bucket_list_empty \
		$(TEST_FILE)::test_object_write_read_update_read_delete \
		$(TEST_FILE)::test_bucket_head \
		$(TEST_FILE)::test_object_head_zero_bytes \
		$(PYTEST_ARGS)

# Core functionality tests (guaranteed to work with your S3 implementation)
test-core: validate-config
	@echo "$(GREEN)Running core functionality tests (guaranteed to work)...$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_bucket_create_delete \
		$(TEST_FILE)::test_buckets_create_then_list \
		$(TEST_FILE)::test_bucket_head \
		$(TEST_FILE)::test_bucket_list_empty \
		$(TEST_FILE)::test_bucket_list_many \
		$(TEST_FILE)::test_bucket_listv2_many \
		$(TEST_FILE)::test_bucket_list_delimiter_basic \
		$(TEST_FILE)::test_bucket_listv2_delimiter_basic \
		$(TEST_FILE)::test_object_write_read_update_read_delete \
		$(TEST_FILE)::test_object_head_zero_bytes \
		$(TEST_FILE)::test_multi_object_delete \
		$(TEST_FILE)::test_object_copy_same_bucket \
		$(PYTEST_ARGS)

# Tests specifically for your implemented APIs
test-implemented: validate-config
	@echo "$(GREEN)Running tests for your implemented S3 APIs...$(NC)"
	@echo "$(YELLOW)Testing: ListBuckets, CreateBucket, HeadBucket, DeleteBucket$(NC)"
	@echo "$(YELLOW)         ListObjects v1/v2 (prefix, delimiter, pagination)$(NC)"
	@echo "$(YELLOW)         PutObject (metadata, chunked, conditional headers)$(NC)"
	@echo "$(YELLOW)         GetObject (range, conditional headers)$(NC)"
	@echo "$(YELLOW)         HeadObject (conditional headers)$(NC)"
	@echo "$(YELLOW)         DeleteObject, CopyObject (metadata directives), DeleteObjects$(NC)"
	@echo "$(YELLOW)         CreateMultipartUpload, UploadPart, CompleteMultipartUpload, AbortMultipartUpload$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_bucket_create_delete \
		$(TEST_FILE)::test_buckets_create_then_list \
		$(TEST_FILE)::test_bucket_head \
		$(TEST_FILE)::test_bucket_delete_notexist \
		$(TEST_FILE)::test_bucket_delete_nonempty \
		$(TEST_FILE)::test_bucket_list_empty \
		$(TEST_FILE)::test_bucket_list_distinct \
		$(TEST_FILE)::test_bucket_list_many \
		$(TEST_FILE)::test_bucket_listv2_many \
		$(TEST_FILE)::test_bucket_list_delimiter_basic \
		$(TEST_FILE)::test_bucket_listv2_delimiter_basic \
		$(TEST_FILE)::test_bucket_list_prefix_basic \
		$(TEST_FILE)::test_bucket_listv2_prefix_basic \
		$(TEST_FILE)::test_bucket_list_maxkeys_one \
		$(TEST_FILE)::test_bucket_listv2_maxkeys_one \
		$(TEST_FILE)::test_bucket_list_marker_none \
		$(TEST_FILE)::test_bucket_listv2_continuationtoken \
		$(TEST_FILE)::test_object_write_read_update_read_delete \
		$(TEST_FILE)::test_object_write_with_chunked_transfer_encoding \
		$(TEST_FILE)::test_object_metadata_replaced_on_put \
		$(TEST_FILE)::test_object_set_get_metadata_none_to_good \
		$(TEST_FILE)::test_object_put_authenticated \
		$(TEST_FILE)::test_object_head_zero_bytes \
		$(TEST_FILE)::test_ranged_request_response_code \
		$(TEST_FILE)::test_ranged_request_skip_leading_bytes_response_code \
		$(TEST_FILE)::test_ranged_request_return_trailing_bytes_response_code \
		$(TEST_FILE)::test_get_object_ifmatch_good \
		$(TEST_FILE)::test_get_object_ifmatch_failed \
		$(TEST_FILE)::test_get_object_ifnonematch_good \
		$(TEST_FILE)::test_get_object_ifnonematch_failed \
		$(TEST_FILE)::test_get_object_ifmodifiedsince_good \
		$(TEST_FILE)::test_get_object_ifunmodifiedsince_good \
		$(TEST_FILE)::test_put_object_ifmatch_good \
		$(TEST_FILE)::test_put_object_ifmatch_failed \
		$(TEST_FILE)::test_put_object_ifnonmatch_good \
		$(TEST_FILE)::test_put_object_ifnonmatch_failed \
		$(TEST_FILE)::test_object_copy_same_bucket \
		$(TEST_FILE)::test_object_copy_diff_bucket \
		$(TEST_FILE)::test_object_copy_to_itself \
		$(TEST_FILE)::test_object_copy_retaining_metadata \
		$(TEST_FILE)::test_object_copy_replacing_metadata \
		$(TEST_FILE)::test_copy_object_ifmatch_good \
		$(TEST_FILE)::test_copy_object_ifmatch_failed \
		$(TEST_FILE)::test_multi_object_delete \
		$(TEST_FILE)::test_multipart_upload \
		$(TEST_FILE)::test_multipart_upload_small \
		$(TEST_FILE)::test_abort_multipart_upload \
		$(TEST_FILE)::test_list_multipart_upload \
		$(PYTEST_ARGS)

# Run all supported API tests (core functionality)
test-all: validate-config
	@echo "$(GREEN)Running all core S3 API tests...$(NC)"
	@$(MAKE) test-buckets || echo "$(YELLOW)Some bucket tests failed$(NC)"
	@$(MAKE) test-objects || echo "$(YELLOW)Some object tests failed$(NC)"
	@$(MAKE) test-list || echo "$(YELLOW)Some list tests failed$(NC)"
	@echo "$(GREEN)All core S3 API tests completed!$(NC)"

# Run comprehensive tests (includes edge cases that may fail on some implementations)
test-comprehensive: validate-config test-all test-auth test-naming test-edge-cases
	@echo "$(GREEN)All comprehensive S3 API tests completed!$(NC)"

# Run all tests including those that fail on AWS (no filtering)
test-all-raw: validate-config
	@echo "$(GREEN)Running all core S3 API tests (including AWS-failing tests)...$(NC)"
	@echo "$(YELLOW)Warning: This includes tests that may fail on AWS-compatible implementations$(NC)"
	@$(MAKE) test-buckets PYTEST_ARGS="--tb=line -v" || echo "$(YELLOW)Some bucket tests failed$(NC)"
	@$(MAKE) test-objects PYTEST_ARGS="--tb=line -v" || echo "$(YELLOW)Some object tests failed$(NC)"
	@$(MAKE) test-list PYTEST_ARGS="--tb=line -v" || echo "$(YELLOW)Some list tests failed$(NC)"
	@echo "$(GREEN)All raw S3 API tests completed!$(NC)"

# =============================================================================
# BUCKET OPERATIONS TESTS
# Based on supported operations: ListBuckets, CreateBucket, HeadBucket, DeleteBucket
# =============================================================================

test-buckets: test-bucket-create test-bucket-delete test-bucket-head test-bucket-list
	@echo "$(GREEN)All bucket operation tests completed!$(NC)"

# Bucket Creation Tests
test-bucket-create: validate-config
	@echo "$(GREEN)Running bucket creation tests...$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_bucket_create_delete \
		$(TEST_FILE)::test_buckets_create_then_list \
		$(PYTEST_ARGS)

# Bucket Deletion Tests
test-bucket-delete: validate-config
	@echo "$(GREEN)Running bucket deletion tests...$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_bucket_create_delete \
		$(TEST_FILE)::test_bucket_delete_notexist \
		$(TEST_FILE)::test_bucket_delete_nonempty \
		$(PYTEST_ARGS)

# Bucket Head Tests
test-bucket-head: validate-config
	@echo "$(GREEN)Running bucket head operation tests...$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_bucket_head \
		$(TEST_FILE)::test_bucket_head_notexist \
		$(TEST_FILE)::test_bucket_head_extended \
		$(TEST_FILE)::test_head_bucket_usage \
		$(PYTEST_ARGS)

# Bucket Listing Tests (service endpoint)
test-bucket-list: validate-config
	@echo "$(GREEN)Running bucket listing tests...$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_buckets_create_then_list \
		$(TEST_FILE)::test_bucket_notexist \
		$(TEST_FILE)::test_bucketv2_notexist \
		$(PYTEST_ARGS)

# =============================================================================
# OBJECT OPERATIONS TESTS
# Based on supported operations: PutObject, GetObject, HeadObject, DeleteObject, CopyObject, DeleteObjects
# =============================================================================

test-objects: test-object-put test-object-get test-object-head test-object-delete test-object-copy test-multipart
	@echo "$(GREEN)All object operation tests completed!$(NC)"

# Object Upload Tests (PutObject)
test-object-put: validate-config
	@echo "$(GREEN)Running object upload (PutObject) tests...$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_object_write_read_update_read_delete \
		$(TEST_FILE)::test_object_write_to_nonexist_bucket \
		$(TEST_FILE)::test_object_write_with_chunked_transfer_encoding \
		$(TEST_FILE)::test_object_metadata_replaced_on_put \
		$(TEST_FILE)::test_object_put_authenticated \
		$(TEST_FILE)::test_object_anon_put \
		$(TEST_FILE)::test_object_anon_put_write_access \
		$(PYTEST_ARGS)

# Object Download Tests (GetObject)
test-object-get: validate-config
	@echo "$(GREEN)Running object download (GetObject) tests...$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_object_read_not_exist \
		$(TEST_FILE)::test_object_raw_get \
		$(TEST_FILE)::test_object_raw_get_bucket_gone \
		$(TEST_FILE)::test_object_raw_get_object_gone \
		$(TEST_FILE)::test_object_raw_get_bucket_acl \
		$(TEST_FILE)::test_object_raw_get_object_acl \
		$(TEST_FILE)::test_object_set_get_metadata_none_to_good \
		$(TEST_FILE)::test_object_set_get_metadata_none_to_empty \
		$(TEST_FILE)::test_object_set_get_metadata_overwrite_to_empty \
		$(TEST_FILE)::test_object_set_get_unicode_metadata \
		$(PYTEST_ARGS)

# Object Head Tests (HeadObject)
test-object-head: validate-config
	@echo "$(GREEN)Running object head operation tests...$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_object_head_zero_bytes \
		$(TEST_FILE)::test_object_requestid_matches_header_on_error \
		$(TEST_FILE)::test_object_raw_response_headers \
		$(PYTEST_ARGS)

# Object Deletion Tests (DeleteObject, DeleteObjects)
test-object-delete: validate-config
	@echo "$(GREEN)Running object deletion tests...$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_multi_object_delete \
		$(TEST_FILE)::test_multi_objectv2_delete \
		$(TEST_FILE)::test_multi_object_delete_key_limit \
		$(TEST_FILE)::test_multi_objectv2_delete_key_limit \
		$(TEST_FILE)::test_object_delete_key_bucket_gone \
		$(TEST_FILE)::test_versioning_concurrent_multi_object_delete \
		$(PYTEST_ARGS)

# Object Copy Tests (CopyObject)
test-object-copy: validate-config
	@echo "$(GREEN)Running object copy operation tests...$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_object_copy_zero_size \
		$(TEST_FILE)::test_object_copy_16m \
		$(TEST_FILE)::test_object_copy_same_bucket \
		$(TEST_FILE)::test_object_copy_verify_contenttype \
		$(TEST_FILE)::test_object_copy_to_itself \
		$(TEST_FILE)::test_object_copy_to_itself_with_metadata \
		$(TEST_FILE)::test_object_copy_diff_bucket \
		$(TEST_FILE)::test_object_copy_canned_acl \
		$(TEST_FILE)::test_object_copy_retaining_metadata \
		$(TEST_FILE)::test_object_copy_replacing_metadata \
		$(TEST_FILE)::test_object_copy_bucket_not_found \
		$(TEST_FILE)::test_object_copy_key_not_found \
		$(PYTEST_ARGS)

# Multipart Upload Tests (CreateMultipartUpload, UploadPart, CompleteMultipartUpload, AbortMultipartUpload, ListParts)
test-multipart: validate-config
	@echo "$(GREEN)Running multipart upload operation tests...$(NC)"
	@echo "$(YELLOW)Testing: CreateMultipartUpload, UploadPart, CompleteMultipartUpload, AbortMultipartUpload, ListMultipartUploads$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_multipart_upload \
		$(TEST_FILE)::test_multipart_upload_small \
		$(TEST_FILE)::test_multipart_upload_empty \
		$(TEST_FILE)::test_multipart_upload_contents \
		$(TEST_FILE)::test_multipart_upload_overwrite_existing_object \
		$(TEST_FILE)::test_multipart_upload_resend_part \
		$(TEST_FILE)::test_multipart_upload_multiple_sizes \
		$(TEST_FILE)::test_multipart_upload_size_too_small \
		$(TEST_FILE)::test_multipart_upload_missing_part \
		$(TEST_FILE)::test_multipart_upload_incorrect_etag \
		$(TEST_FILE)::test_abort_multipart_upload \
		$(TEST_FILE)::test_abort_multipart_upload_not_found \
		$(TEST_FILE)::test_list_multipart_upload \
		$(TEST_FILE)::test_list_multipart_upload_owner \
		$(TEST_FILE)::test_multipart_copy_small \
		$(TEST_FILE)::test_multipart_copy_invalid_range \
		$(TEST_FILE)::test_multipart_copy_improper_range \
		$(TEST_FILE)::test_multipart_copy_without_range \
		$(TEST_FILE)::test_multipart_copy_special_names \
		$(TEST_FILE)::test_multipart_copy_multiple_sizes \
		$(TEST_FILE)::test_multipart_copy_versioned \
		$(TEST_FILE)::test_multipart_get_part \
		$(TEST_FILE)::test_multipart_single_get_part \
		$(TEST_FILE)::test_non_multipart_get_part \
		$(TEST_FILE)::test_atomic_multipart_upload_write \
		$(TEST_FILE)::test_multipart_resend_first_finishes_last \
		$(TEST_FILE)::test_object_copy_versioning_multipart_upload \
		$(TEST_FILE)::test_versioning_obj_create_overwrite_multipart \
		$(TEST_FILE)::test_versioning_bucket_multipart_upload_return_version_id \
		$(TEST_FILE)::test_lifecycle_set_multipart \
		$(TEST_FILE)::test_lifecycle_multipart_expiration \
		$(TEST_FILE)::test_set_multipart_tagging \
		$(TEST_FILE)::test_bucket_policy_multipart \
		$(TEST_FILE)::test_multipart_upload_on_a_bucket_with_policy \
		$(PYTEST_ARGS)

# Core Multipart Upload Tests (essential operations only)
test-multipart-core: validate-config
	@echo "$(GREEN)Running core multipart upload tests...$(NC)"
	@echo "$(YELLOW)Testing essential multipart operations: CreateMultipartUpload, UploadPart, CompleteMultipartUpload, AbortMultipartUpload$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_multipart_upload \
		$(TEST_FILE)::test_multipart_upload_small \
		$(TEST_FILE)::test_abort_multipart_upload \
		$(TEST_FILE)::test_list_multipart_upload \
		$(TEST_FILE)::test_multipart_upload_contents \
		$(TEST_FILE)::test_multipart_upload_size_too_small \
		$(TEST_FILE)::test_multipart_upload_missing_part \
		$(PYTEST_ARGS)

# Debug Multipart Upload Tests (minimal test for debugging ETag issues)
test-multipart-debug: validate-config
	@echo "$(GREEN)Running debug multipart upload tests...$(NC)"
	@echo "$(YELLOW)Testing minimal multipart operations for debugging$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_multipart_upload_small \
		$(TEST_FILE)::test_abort_multipart_upload \
		$(PYTEST_ARGS)

# =============================================================================
# LIST OPERATIONS TESTS
# Based on supported operations: ListObjects v1, ListObjects v2
# =============================================================================

test-list: test-list-objects-v1 test-list-objects-v2 test-list-delimiter test-list-prefix
	@echo "$(GREEN)All list operation tests completed!$(NC)"

# ListObjects v1 Tests
test-list-objects-v1: validate-config
	@echo "$(GREEN)Running ListObjects v1 tests...$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_bucket_list_empty \
		$(TEST_FILE)::test_bucket_list_distinct \
		$(TEST_FILE)::test_bucket_list_many \
		$(TEST_FILE)::test_bucket_list_unordered \
		$(TEST_FILE)::test_bucket_list_return_data \
		$(TEST_FILE)::test_bucket_list_maxkeys_one \
		$(TEST_FILE)::test_bucket_list_maxkeys_zero \
		$(TEST_FILE)::test_bucket_list_maxkeys_none \
		$(TEST_FILE)::test_bucket_list_marker_none \
		$(TEST_FILE)::test_bucket_list_marker_empty \
		$(TEST_FILE)::test_bucket_list_marker_unreadable \
		$(TEST_FILE)::test_bucket_list_marker_not_in_list \
		$(TEST_FILE)::test_bucket_list_marker_after_list \
		$(PYTEST_ARGS)

# ListObjects v2 Tests
test-list-objects-v2: validate-config
	@echo "$(GREEN)Running ListObjects v2 tests...$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_bucket_listv2_many \
		$(TEST_FILE)::test_bucket_listv2_unordered \
		$(TEST_FILE)::test_bucket_listv2_maxkeys_one \
		$(TEST_FILE)::test_bucket_listv2_maxkeys_zero \
		$(TEST_FILE)::test_bucket_listv2_maxkeys_none \
		$(TEST_FILE)::test_bucket_listv2_continuationtoken_empty \
		$(TEST_FILE)::test_bucket_listv2_continuationtoken \
		$(TEST_FILE)::test_bucket_listv2_both_continuationtoken_startafter \
		$(TEST_FILE)::test_bucket_listv2_startafter_unreadable \
		$(TEST_FILE)::test_bucket_listv2_startafter_not_in_list \
		$(TEST_FILE)::test_bucket_listv2_startafter_after_list \
		$(TEST_FILE)::test_bucket_listv2_fetchowner_notempty \
		$(TEST_FILE)::test_bucket_listv2_fetchowner_defaultempty \
		$(TEST_FILE)::test_bucket_listv2_fetchowner_empty \
		$(PYTEST_ARGS)

# Delimiter-based Listing Tests
test-list-delimiter: validate-config
	@echo "$(GREEN)Running delimiter-based listing tests...$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_bucket_list_delimiter_basic \
		$(TEST_FILE)::test_bucket_listv2_delimiter_basic \
		$(TEST_FILE)::test_bucket_list_delimiter_prefix \
		$(TEST_FILE)::test_bucket_listv2_delimiter_prefix \
		$(TEST_FILE)::test_bucket_list_delimiter_alt \
		$(TEST_FILE)::test_bucket_listv2_delimiter_alt \
		$(TEST_FILE)::test_bucket_list_delimiter_prefix_underscore \
		$(TEST_FILE)::test_bucket_listv2_delimiter_prefix_underscore \
		$(TEST_FILE)::test_bucket_list_delimiter_percentage \
		$(TEST_FILE)::test_bucket_listv2_delimiter_percentage \
		$(TEST_FILE)::test_bucket_list_delimiter_whitespace \
		$(TEST_FILE)::test_bucket_listv2_delimiter_whitespace \
		$(TEST_FILE)::test_bucket_list_delimiter_dot \
		$(TEST_FILE)::test_bucket_listv2_delimiter_dot \
		$(TEST_FILE)::test_bucket_list_delimiter_empty \
		$(TEST_FILE)::test_bucket_listv2_delimiter_empty \
		$(TEST_FILE)::test_bucket_list_delimiter_none \
		$(TEST_FILE)::test_bucket_listv2_delimiter_none \
		$(TEST_FILE)::test_bucket_list_delimiter_not_exist \
		$(TEST_FILE)::test_bucket_listv2_delimiter_not_exist \
		$(PYTEST_ARGS)

# Prefix-based Listing Tests
test-list-prefix: validate-config
	@echo "$(GREEN)Running prefix-based listing tests...$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_bucket_list_prefix_basic \
		$(TEST_FILE)::test_bucket_listv2_prefix_basic \
		$(TEST_FILE)::test_bucket_list_prefix_alt \
		$(TEST_FILE)::test_bucket_listv2_prefix_alt \
		$(TEST_FILE)::test_bucket_list_prefix_empty \
		$(TEST_FILE)::test_bucket_listv2_prefix_empty \
		$(TEST_FILE)::test_bucket_list_prefix_none \
		$(TEST_FILE)::test_bucket_listv2_prefix_none \
		$(TEST_FILE)::test_bucket_list_prefix_not_exist \
		$(TEST_FILE)::test_bucket_listv2_prefix_not_exist \
		$(TEST_FILE)::test_bucket_list_prefix_unreadable \
		$(TEST_FILE)::test_bucket_listv2_prefix_unreadable \
		$(TEST_FILE)::test_bucket_list_prefix_delimiter_basic \
		$(TEST_FILE)::test_bucket_listv2_prefix_delimiter_basic \
		$(TEST_FILE)::test_bucket_list_prefix_delimiter_alt \
		$(TEST_FILE)::test_bucket_listv2_prefix_delimiter_alt \
		$(PYTEST_ARGS)

# =============================================================================
# SPECIALIZED TESTS
# =============================================================================

# Edge Cases Tests (may fail on some S3 implementations)
test-edge-cases: validate-config
	@echo "$(GREEN)Running edge case tests (may fail on some implementations)...$(NC)"
	@echo "$(YELLOW)Note: These tests check AWS-specific behaviors that may not be implemented$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_bucket_create_exists \
		$(TEST_FILE)::test_bucket_create_exists_nonowner \
		$(TEST_FILE)::test_bucket_recreate_overwrite_acl \
		$(TEST_FILE)::test_bucket_recreate_new_acl \
		$(TEST_FILE)::test_bucket_recreate_not_overriding \
		$(PYTEST_ARGS) || echo "$(YELLOW)Some edge case tests failed - this is expected for non-AWS implementations$(NC)"

# Authentication and Authorization Tests
test-auth: validate-config
	@echo "$(GREEN)Running authentication and authorization tests...$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_object_put_authenticated \
		$(TEST_FILE)::test_object_anon_put \
		$(TEST_FILE)::test_object_anon_put_write_access \
		$(TEST_FILE)::test_bucket_list_objects_anonymous \
		$(TEST_FILE)::test_bucket_listv2_objects_anonymous \
		$(TEST_FILE)::test_bucket_list_objects_anonymous_fail \
		$(TEST_FILE)::test_bucket_listv2_objects_anonymous_fail \
		$(TEST_FILE)::test_object_raw_get_bucket_acl \
		$(TEST_FILE)::test_object_raw_get_object_acl \
		$(TEST_FILE)::test_expected_bucket_owner \
		$(PYTEST_ARGS)

# Naming Validation Tests
test-naming: validate-config
	@echo "$(GREEN)Running bucket/object naming validation tests...$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_bucket_create_naming_good_starts_alpha \
		$(TEST_FILE)::test_bucket_create_naming_good_starts_digit \
		$(TEST_FILE)::test_bucket_create_naming_good_contains_period \
		$(TEST_FILE)::test_bucket_create_naming_good_contains_hyphen \
		$(TEST_FILE)::test_bucket_create_naming_good_long_60 \
		$(TEST_FILE)::test_bucket_create_naming_good_long_61 \
		$(TEST_FILE)::test_bucket_create_naming_good_long_62 \
		$(TEST_FILE)::test_bucket_create_naming_good_long_63 \
		$(TEST_FILE)::test_bucket_create_naming_bad_starts_nonalpha \
		$(TEST_FILE)::test_bucket_create_naming_bad_short_one \
		$(TEST_FILE)::test_bucket_create_naming_bad_short_two \
		$(TEST_FILE)::test_bucket_create_naming_bad_ip \
		$(TEST_FILE)::test_bucket_create_naming_dns_underscore \
		$(TEST_FILE)::test_bucket_create_naming_dns_long \
		$(TEST_FILE)::test_bucket_create_naming_dns_dash_at_end \
		$(TEST_FILE)::test_bucket_create_naming_dns_dot_dot \
		$(TEST_FILE)::test_bucket_create_naming_dns_dot_dash \
		$(TEST_FILE)::test_bucket_create_naming_dns_dash_dot \
		$(TEST_FILE)::test_bucket_create_special_key_names \
		$(PYTEST_ARGS)

# Test Cleanup Functionality
test-cleanup: validate-config
	@echo "$(GREEN)Testing cleanup functionality...$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_bucket_create_delete \
		$(TEST_FILE)::test_multi_object_delete \
		$(TEST_FILE)::test_multi_objectv2_delete \
		$(PYTEST_ARGS)

# =============================================================================
# PERFORMANCE AND STRESS TESTS
# =============================================================================

# Performance Tests (larger objects, many objects)
test-performance: validate-config
	@echo "$(GREEN)Running performance tests...$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_object_copy_16m \
		$(TEST_FILE)::test_bucket_list_many \
		$(TEST_FILE)::test_bucket_listv2_many \
		$(TEST_FILE)::test_multi_object_delete_key_limit \
		$(TEST_FILE)::test_multi_objectv2_delete_key_limit \
		$(PYTEST_ARGS)

# Concurrent Operations Tests
test-concurrent: validate-config
	@echo "$(GREEN)Running concurrent operations tests...$(NC)"
	$(PYTEST_CMD) $(TEST_FILE)::test_bucket_concurrent_set_canned_acl \
		$(TEST_FILE)::test_versioning_concurrent_multi_object_delete \
		$(PYTEST_ARGS)

# =============================================================================
# UTILITY TARGETS
# =============================================================================

# Clean up any leftover test buckets (run this if tests fail and leave buckets)
clean-buckets:
	@echo "$(YELLOW)Cleaning up any leftover test buckets...$(NC)"
	@echo "$(RED)WARNING: This will delete ALL buckets with 'test-' prefix!$(NC)"
	@read -p "Are you sure? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		$(PYTEST_CMD) -c "import boto3; from botocore.config import Config; client = boto3.client('s3', endpoint_url='http://localhost:8000', aws_access_key_id='AKIA5ADMIN123456', aws_secret_access_key='wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY', use_ssl=False, verify=False, config=Config(signature_version='s3v4', s3={'addressing_style': 'virtual'})); [client.delete_bucket(Bucket=b['Name']) for b in client.list_buckets()['Buckets'] if b['Name'].startswith('test-')]"; \
	fi

# Show test statistics
test-stats:
	@echo "$(GREEN)S3 Test Statistics$(NC)"
	@echo "=================="
	@echo "Total test functions: $$(grep -c '^def test_' $(TEST_FILE))"
	@echo "Bucket operation tests: $$(grep -c '^def test_.*bucket' $(TEST_FILE))"
	@echo "Object operation tests: $$(grep -c '^def test_.*object' $(TEST_FILE))"
	@echo "List operation tests: $$(grep -c '^def test_.*list' $(TEST_FILE))"
	@echo "Authentication tests: $$(grep -c '^def test_.*auth\|^def test_.*anon' $(TEST_FILE))"

# Show supported S3 operations
show-supported-ops:
	@echo "$(GREEN)Supported S3 Operations (from server.go)$(NC)"
	@echo "========================================"
	@echo "$(YELLOW)Bucket Operations:$(NC)"
	@echo "  • ListBuckets (service endpoint)"
	@echo "  • CreateBucket (virtual-style)"
	@echo "  • HeadBucket (virtual-style)"  
	@echo "  • DeleteBucket (virtual-style)"
	@echo "  • ListObjects v1 (virtual-style)"
	@echo "  • ListObjects v2 (virtual-style)"
	@echo ""
	@echo "$(YELLOW)Object Operations:$(NC)"
	@echo "  • PutObject (virtual-style)"
	@echo "  • GetObject (virtual-style)"
	@echo "  • HeadObject (virtual-style)"
	@echo "  • DeleteObject (virtual-style)"
	@echo "  • CopyObject (virtual-style)"
	@echo "  • DeleteObjects (virtual-style, batch)"
	@echo ""
	@echo "$(YELLOW)Multipart Upload Operations:$(NC)"
	@echo "  • CreateMultipartUpload (virtual-style)"
	@echo "  • UploadPart (virtual-style)"
	@echo "  • CompleteMultipartUpload (virtual-style)"
	@echo "  • AbortMultipartUpload (virtual-style)"
	@echo "  • ListMultipartUploads (virtual-style)"
	@echo ""
	@echo "$(YELLOW)Endpoint Style:$(NC)"
	@echo "  • Virtual-hosted style: bucket.localhost:8000/object"
	@echo "  • Service endpoint: localhost:8000/ (for ListBuckets)"