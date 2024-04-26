lu = require('luaunit')
string_utils = require('string_utils')

function test_string_with_hypyen()
  local backend_name = "west-site1-west-site1-local-ingress_3480"
  local site_name = "west-site1"

  local pattern = string_utils.escape_pattern(site_name)
  local site_name_from_match = backend_name:match(pattern)
  lu.assertNotNil(site_name_from_match)
  lu.assertEquals(site_name_from_match, site_name)
end

function test_escape_string_with_no_reserved_characters()
  local str = "test123"
  local escaped_str = string_utils.escape_pattern(str)
  lu.assertNotNil(escaped_str)
  lu.assertEquals(escaped_str, str)
end

function test_empty_str()
  local str = ""
  local escaped_str = string_utils.escape_pattern(str)
  lu.assertNotNil(escaped_str)
  lu.assertEquals(escaped_str, str)
end

function test_string_with_multiple_hyphens()
  local str = "test--site"
  local text = "The new backend name is stratum_test--site-local-ingress"
  local escaped_str = string_utils.escape_pattern(str)
  lu.assertNotNil(escaped_str)
  lu.assertEquals(escaped_str, "test%-%-site")

  local substr = text:match(escaped_str)
  lu.assertEquals(substr, "test--site")
end

function test_string_with_dot()
  local name = "foo.com"
  local text = "the dns name is foo.com"
  local escaped_name = string_utils.escape_pattern(name)
  lu.assertEquals(escaped_name, "foo%.com")

  local substr = text:match(escaped_name)
  lu.assertNotNil(substr)
  lu.assertEquals(name, substr)
end

function test_string_with_multiple_dots()
  local name = "foo...com"
  local text = "the dns name is foo...com"
  local escaped_name = string_utils.escape_pattern(name)
  lu.assertEquals(escaped_name, "foo%.%.%.com")

  local substr = text:match(escaped_name)
  lu.assertNotNil(substr)
  lu.assertEquals(name, substr)
end

function test_string_with_hyphen_and_dot()
  local name = "foo.com-site1"
  local text = "the dns name is foo.com-site1"
  local escaped_name = string_utils.escape_pattern(name)
  lu.assertEquals(escaped_name, "foo%.com%-site1")

  local substr = text:match(escaped_name)
  lu.assertNotNil(substr)
  lu.assertEquals(name, substr)
end

os.exit(lu.LuaUnit.run())
