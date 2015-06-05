module ImportIssuesHelper
  include ApplicationHelper
  include CustomFieldsHelper
  
  def values_for_core_field(core_field, import_action, default_value = nil)
    value = nil
    project = import_action.project
    field_id = "fields[#{core_field}][value]"
    case core_field
      when 'assigned_to_id'
        value = select_tag(field_id, options_from_collection_for_select(project.assignable_users, "id", "name", default_value))
      when 'category_id'
        value = select_tag(field_id, options_from_collection_for_select(project.issue_categories, "id", "name", default_value))
      when 'fixed_version_id'
        value = select_tag(field_id, options_from_collection_for_select(project.versions.open, "id", "name", default_value))
      when 'done_ratio'
        value = select_tag(field_id, options_for_select((0..10).to_a.collect {|r| ["#{r*10} %", r*10] }, default_value ))
      when 'is_private'
        value = check_box_tag(field_id, 1, default_value != nil)
      when 'subject'
        value = text_field_tag(field_id, default_value, {:size => 60, :maxlength => 255})
      when 'description'
        value = text_area_tag(field_id, default_value, {:cols => 60, :rows => 5, :no_label => true})
      when 'status_id'
        value = select_tag(field_id, options_from_collection_for_select(import_action.tracker.issue_statuses, "id", "name", default_value))
      when 'priority_id'
        value = select_tag(field_id, options_from_collection_for_select(IssuePriority.active, "id", "name", default_value))
      when 'parent_issue_id'
        value = text_field_tag(field_id, default_value, {:size => 10})
      when 'start_date'
        value = text_field_tag(field_id, default_value, {:size => 10, :class => "import-date"})         
      when 'due_date'
        value = text_field_tag(field_id, default_value, {:size => 10, :class => "import-date"}) 
      when 'estimated_hours'
        value = text_field_tag(field_id, default_value, {:size => 3})     
      when 'spent_on'
        value = text_field_tag(field_id, default_value, {:size => 10, :class => "import-date"}) 
      when 'hours'
        value = text_field_tag(field_id, default_value, {:size => 10, :class => "import-date"})                                      
      else        
        value = text_field_tag(field_id, nil, {:size => 60, :maxlength => 255})
    end
    
    value     
  end
  
  def values_for_custom_field(field_id, custom_value)
    id = "fields_#{field_id}_value"
    name = "fields[#{field_id}][value]"
    if custom_value.custom_field.field_format == "bool"
      value = check_box_tag(name, 1, true, {:id => id })
    else
      value = custom_field_tag(field_id, custom_value)
      sub_id = "#{field_id}_custom_field_values_#{field_id}"
      sub_name = "#{field_id}[custom_field_values][#{field_id}]"
      value.sub!(sub_id,id)      
      value.sub!(sub_name,name)
    end
    value.html_safe
  end

  def values_for_time_entry(core_field, import_action, default_value = nil)
    value = nil
    project = import_action.project
    field_id = "time_entry[#{core_field}][value]"
    case core_field
      when 'users'
        value = select_tag(field_id, options_from_collection_for_select(project.assignable_users, "id", "name", default_value), {:multiple => true})
      when 'activity_id'
        value = select_tag(field_id, options_from_collection_for_select(project.activities, "id", "name", default_value))
      when 'fixed_version_id'
        value = select_tag(field_id, options_from_collection_for_select(project.versions.open, "id", "name", default_value))
      when 'done_ratio'
        value = select_tag(field_id, options_for_select((0..10).to_a.collect {|r| ["#{r*10} %", r*10] }, default_value ))
      when 'is_private'
        value = check_box_tag(field_id, 1, default_value != nil)
      when 'subject'
        value = text_field_tag(field_id, default_value, {:size => 60, :maxlength => 255})
      when 'description'
        value = text_area_tag(field_id, default_value, {:cols => 60, :rows => 5, :no_label => true})
      when 'status_id'
        value = select_tag(field_id, options_from_collection_for_select(import_action.tracker.issue_statuses, "id", "name", default_value))
      when 'priority_id'
        value = select_tag(field_id, options_from_collection_for_select(IssuePriority.active, "id", "name", default_value))
      when 'parent_issue_id'
        value = text_field_tag(field_id, default_value, {:size => 10})
      when 'start_date'
        value = text_field_tag(field_id, default_value, {:size => 10, :class => "import-date"})         
      when 'due_date'
        value = text_field_tag(field_id, default_value, {:size => 10, :class => "import-date"}) 
      when 'estimated_hours'
        value = text_field_tag(field_id, default_value, {:size => 3})     
      when 'spent_on'
        value = text_field_tag(field_id, default_value, {:size => 10, :class => "import-date"}) 
      when 'hours'
        value = text_field_tag(field_id, default_value, {:size => 10, :class => "import-date"})                                      
      else        
        value = text_field_tag(field_id, nil, {:size => 60, :maxlength => 255})
    end
    
    value     
  end  
  
  def values_selected_for_field(field, import_action)
    source = import_action.source_for(field)
    value = import_action.value_for(field)
    tag = nil 
    
    case source
      when "ignore"
        tag = no_import_field_span
      when "redmine"
        if field.to_i == 0
          tag = content_tag(:span,values_for_core_field(field,import_action,value),:class => 'import-redmine')
        else
          cf = CustomField.find(field)
          cv = CustomValue.new(:custom_field => cf, :value => value)
          tag = content_tag(:span,values_for_custom_field(field,cv),:class => 'import-redmine')          
        end
      when "file"
        tag = content_tag(:span,select_tag("fields[#{field}][value]", options_for_select(import_action.headers, value)),:class => 'import-file')  
    end
    
    tag     
  end

  def values_selected_for_time_entry(field, import_action)
    source = import_action.source_for(field)
    value = import_action.value_for(field)
    tag = nil 
    
    case source
      when "ignore"
        tag = no_import_field_span
      when "redmine"
        tag = content_tag(:span,values_for_time_entry(field,import_action,value),:class => 'import-redmine')
      when "file"
        tag = content_tag(:span,select_tag("time_entry[#{field}][value]", options_for_select(import_action.headers, value)),:class => 'import-file')  
    end
    
    tag     
  end

    
  def no_import_field_span(text = nil)
    content_tag('span',text, :class => 'import-ignore')    
  end
  
  def readable_field_name(field)
    name = ""
    if field.to_i == 0
      name = l("field_#{field}".sub(/_id$/, ''))
    else
      name = CustomField.find(field.to_i).name
    end
    name
  end
  
  def readable_field_value(field, mapping)
    text = readable_field_value_from_file(mapping) if mapping["source"] == "file"
    text = readable_field_value_from_redmine(field, mapping) if mapping["source"] == "redmine"
    text    
  end
  
  def readable_field_value_from_file(mapping)
    @import.headers.detect{|c| c.last == mapping["value"].to_i}.first if @import.headers
  end
  
  def readable_field_value_from_redmine(field, mapping)
    value = mapping["value"]
  
    if field.to_i == 0 #core value
      value = readable_core_field_value(field, value)
    else #TODO: Users and versions
      cf = CustomField.find(field.to_i)
      value = format_value(value, cf)
    end
    value 
  end
  
  def readable_value_for_time_entry(import_action, time_field, mapping)
    value = mapping["value"]
    if mapping["source"] == "file"
      text = readable_field_value_from_file(mapping) 
    else
      case time_field
      when 'users'
        text = import_action.project.assignable_users.select {|u| value.include?(u.id.to_s) }.join('<br />').html_safe
      when 'hours'
        text = value.to_f
      when 'comments'
        text = value
      when 'activity_id'
        text = import_action.project.activities.detect {|a| a.id == value.to_i}.name rescue 'N/A'
      when 'spent_on'
        text = value.to_date rescue 'Invalid date'
      end
    end
    text ||= ""
  end
  
  def readable_core_field_value(field, value)
    case field
      when 'assigned_to_id'
        value = @import.project.assignable_users.detect{|u| u.id == value.to_i}.name rescue l(:error_value_not_exists)
      when 'category_id'
        value = @import.project.issue_categories.detect{|u| u.id == value.to_i}.name rescue l(:error_value_not_exists)
      when 'fixed_version_id'
        value = @import.project.versions.open.detect{|u| u.id == value.to_i}.name rescue l(:error_value_not_exists)
      when 'done_ratio'
        value = "#{value} %"
      when 'is_private'
        value = value.to_i == 1 ? l(:general_text_Yes) : l(:general_text_No)
      when 'subject'
        value = value
      when 'description'
        value = value
      when 'status_id'
        value = @import.tracker.issue_statuses.detect{|u| u.id == value.to_i}.name rescue l(:error_value_not_exists)
      when 'priority_id'
        value = IssuePriority.active.detect{|u| u.id == value.to_i}.name rescue l(:error_value_not_exists)
      when 'parent_issue_id'
        issue = Issue.find(value.to_i)
        value = "#{issue.tracker.name} ##{issue.id} #{issue.subject}"
      when 'start_date'
        value = format_date(value.to_date)         
      when 'due_date'
        value = format_date(value.to_date) 
      when 'estimated_hours'
        value = value                                
      else        
        value = value
      end
    value
  end
  
  def result_value(value)
    value ? l(:general_text_Yes) : l(:general_text_No)
  end
  
  def import_errors(result)
    html = ""
    if !result['valid']
      html << "<div id='errorExplanation'>"
      result['errors'].each do |error|
        html << "#{h error}<br />\n"
      end
      if result['time_entry_errors'].any?
        html << "<strong>#{l(:label_spent_time)}</strong><hr>"
        result['time_entry_errors'].each do |error|
          html << "#{h error}<br />\n"
        end        
      end
      html << "</div>\n"
    else
      html << "<div class='flash notice'>Ok</div>" 
    end
    html.html_safe
  end  
end
