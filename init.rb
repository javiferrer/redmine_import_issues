require 'redmine'

Redmine::Plugin.register :redmine_import_issues do
  name 'Import Issues plugin'
  author 'Javi Ferrer'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
  
  project_module :redmine_import_issues do
    permission :import_issues, :import_issues => :index
    permission :import_issues_templates, :import_issues => :index
    menu :project_menu, :import_issues, { :controller => 'import_issues', :action => 'index' }, :caption => :label_import_issues
  end
  
end
