# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
RedmineApp::Application.routes.draw do
  resources :projects do
    resources :import_issues do
      member do
        get 'prepare'
        get 'overview'
        get 'recover'
        get 'download'
        get 'process'
        get 'load_values_for_field'
        get 'load_values_for_time_entry'
        get 'import'
        
        get 'validate'
               
        put 'change_file'
        put 'change_file_recover'
      end
    end
  end
end