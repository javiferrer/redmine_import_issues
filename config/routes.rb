# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
RedmineApp::Application.routes.draw do
  resources :import_issues
  get 'projects/:id/import_issues', :to => 'import_issues#index'
  get 'projects/:id/import_issues/prepare/:import_id', :to => 'import_issues#prepare'
  get 'projects/:id/import_issues/overview/:import_id', :to => 'import_issues#overview'
  get 'projects/:id/import_issues/validate/:import_id', :to => 'import_issues#validate'
  get 'projects/:id/import_issues/process/:import_id', :to => 'import_issues#process'
  post 'projects/:id/import_issues/validate/:import_id', :to => 'import_issues#validate', :as => 'import_action_validate'
  put 'projects/:id/import_issues/change_file/:import_id', :to => 'import_issues#change_file', :as => 'import_change_file'
  put 'projects/:id/import_issues/change_file_recover/:import_id', :to => 'import_issues#change_file_recover', :as => 'import_change_file_recover'  
  get 'projects/:id/import_issues/import/:import_id', :to => 'import_issues#import', :as => 'import_save_issues'
  get 'projects/:id/import_issues/recover/:import_id', :to => 'import_issues#recover', :as => 'recover_template'
  #get 'projects/:id/import_issues/load_values_for_field/:custom_field_id', :to => 'import_issues#load_values_for_field'
  get 'projects/:id/import_issues/download/:import_id', :to => 'import_issues#download', :as => 'download_template_file'  
  match 'projects/:id/import_issues/load_values_for_field/:import_id', :via => :get, :to => 'import_issues#load_values_for_field', :as => 'values_for_field'
  match 'projects/:id/import_issues/load_values_for_time_entry/:import_id', :via => :get, :to => 'import_issues#load_values_for_time_entry', :as => 'values_for_time_entry'

end