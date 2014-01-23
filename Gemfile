source "https://rubygems.org"

ruby '2.0.0'

# Declare your gem's dependencies in ffcrm_import_leads.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# jquery-rails is used by the dummy application
gem "jquery-rails"

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use debugger
# gem 'debugger'
gem 'fat_free_crm', :git => 'git://github.com/fatfreecrm/fat_free_crm.git'

group :development do
  # don't load these gems in travis
  unless ENV["CI"]
    #added
    gem 'better_errors'
    gem 'binding_of_caller', :platforms=>[:mri_19, :rbx]
    gem 'meta_request'
  end
end




