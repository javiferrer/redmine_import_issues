require 'redmine'

Redmine::Plugin.register :redmine_import_issues do
  name 'Import Issues plugin'
  author 'Francisco Javier Perez Ferrer'
  description 'This plugin allows to import issues and time entries'
  version '1.0.0'
  url 'http://javiferrer.es'
  author_url 'mailto:contacto@javiferrer.es'
  
  project_module :redmine_import_issues do
    permission :import_issues, :import_issues => [:index, :prepare, :change_file_recover, 
                                                    :recover, :download, :overview, :create, 
                                                    :change_file, :load_values_for_field, 
                                                    :load_values_for_time_entry, :update, 
                                                    :validate, :import
                                                  ]
    permission :import_issues_delete_templates, :import_issues => [:destroy]
   
    menu :project_menu, :import_issues, { :controller => 'import_issues', :action => 'index' }, 
        :caption => :label_import_issues, :param => :project_id
  end
  
end
