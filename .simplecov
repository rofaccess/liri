SimpleCov.profiles.define "liri" do
  # Next line filter all test folder contains
  # add_filter %r{^/spec/}
  add_filter "spec"

  ## Add custom groups
  add_group 'Lib', 'lib'
end