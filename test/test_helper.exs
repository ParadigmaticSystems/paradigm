ExUnit.start()
Code.require_file("support/conformance_test_suite.ex", __DIR__)
for file <- Path.wildcard(Path.join([__DIR__, "support/conformance_test_suite/*.ex"])) do
  Code.require_file(file)
end
