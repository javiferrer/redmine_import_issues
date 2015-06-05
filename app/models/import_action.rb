# Import Issues Plugin for Redmine
# Copyright (C) 2013  Francisco Javier Perez Ferrer
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class ImportAction < ActiveRecord::Base
  unloadable
  
  include ImportIssuesEngine
  
  belongs_to :user
  belongs_to :project
  belongs_to :tracker
  belongs_to :template, :class_name => "ImportAction"
  
  before_create :set_default_info
  before_save :check_fields
  
  acts_as_attachable
  
  attr_accessor :book
  
  serialize :fields, Hash
  serialize :time_entry_fields, Hash
  serialize :log, Hash
  
  TIME_ENTRY_FIELDS = ["spent_on", "hours", "comments", "activity_id", "users"]
  
  def issue_fields=(hash)
    self.fields = hash.to_hash.select {|k, v| v["source"] != "ignore"} 
  end
  
  def time_entries_fields=(hash)
    self.time_entry_fields = hash.to_hash.select {|k, v| v["source"] != "ignore"} 
  end
  
  def headers
    load_book
    self.book.headers
  end
  
  def custom_fields
    (project.all_issue_custom_fields & tracker.custom_fields.all).sort_by{|c| [c.is_required? ? 0 : 1, c.name]}
  end
  
  def core_fields
    core_fields = (Tracker::CORE_FIELDS_ALL + 
      (Tracker::CORE_FIELDS & self.tracker.core_fields)).uniq - ['project_id', 'tracker_id']
    
    core_fields << "status_id"
  end
  
  def core_fields_mapping_from_redmine
    map = {}
    self.fields.each{|k,v|
      map[k] = v["value"] if k.to_i == 0 && v["source"] == "redmine" 
    }
    map
  end
  
  def custom_fields_mapping_from_redmine
    map = {}
    self.fields.each{|k,v|
      map[k] = v["value"] if k.to_i != 0 && v["source"] == "redmine" 
    }
    map  
  end  
  
  def core_fields_mapping_from_file
    map = {}
    self.fields.each{|k,v|
      map[k] = v["value"].to_s if k.to_i == 0 && v["source"] == "file" 
    }
    map
  end
  
  def get_core_value(field, row)
    v, value = row[:value], row[:value]
    format = row[:format]
    case field
    when "status_id"
      if format == :string
        v = IssueStatus.find_by_name(value).id rescue -1
      else
        v = IssueStatus.find_by_id(value).id rescue -1
      end
    when "parent_issue_id"
      v = value.to_i
      v = v == 0 ? nil : v
    when "is_private"
      v = value.to_i == 0 ? false : true
    when "category_id"
      if format == :string
        v = Category.find_by_name(value).id rescue -1
      else
        v = Category.find_by_id(value).id rescue -1
      end
    when "fixed_version_id"
      if format == :string
        v = Version.find_by_name(value).id rescue -1
      else
        v = Version.find_by_id(value).id rescue -1
      end                  
    else
      v = value.to_s      
    end
    v
  end
  
  def custom_fields_mapping_from_file
    map = {}
    self.fields.each{|k,v|
      map[k] = v["value"] if k.to_i != 0 && v["source"] == "file" 
    }
    map   
  end    
  
  def book_file
    self.attachments.last
  end
  
  def template_file
    self.template.book_file if template
  end
  
  def check_file
    ImportIssuesEngine::Book.check_file(self.attachments.last.diskfile)
  end
  
  def self.load_templates(project)
    ImportAction.where(:is_template => true, :project_id => project)
  end
  
  def self.load_in_progress
    ImportAction.where(:status => 'in_progress')
  end
  
  def source_for(field)
    if TIME_ENTRY_FIELDS.include?(field)
      self.time_entry_fields[field.to_s]["source"] rescue "ignore"
    else
      self.fields[field.to_s]["source"] rescue "ignore"
    end
  end
  
  def value_for(field)
    if TIME_ENTRY_FIELDS.include?(field)
      self.time_entry_fields[field.to_s]["value"] rescue nil
    else
      self.fields[field.to_s]["value"] rescue nil
    end
  end  
  
  def fields_mapping
    self.fields.each do |k,v|
    end
  end
  
  def load_row(row)
    load_book if self.book.nil?
    book.load_row(row)
  end
  
  def load_or_create_issue(issue_mapping)
    if self.field_for_update
      cf_for_update_value = issue_mapping["custom_field_values"][self.field_for_update.to_s]
      i = self.project.issues.joins(:custom_values).where("custom_field_id = #{self.field_for_update}
      and tracker_id = #{self.tracker_id} and custom_values.value = '#{cf_for_update_value.to_s}'").first

      
      if i
        issue = Issue.find(i.id)
        init_journal(self.user, issue)    
        issue.attributes = issue_mapping 
      end
      
    else      
      issue = Issue.new(issue_mapping)
    end
    issue = issue.nil? ? Issue.new(issue_mapping) : issue    
    issue
  end
  
  def create_issue_journal(attributes)

    journal = Journal.new(:journalized => issue, :user => self.user)
    diferencias = @attributes_before_change.diff(attributes)
    diferencias.except!("updated_on", "id")
    diferencias.each do |k, v|
      if k.to_i > 0
        journal.details << JournalDetail.new(:property => 'cf',
                                                                :prop_key => c,
                                                                :old_value => before,
                                                                :value => after)            
      else
        journal.details << JournalDetail.new(:property => 'attr',
                                                                :prop_key => k,
                                                                :old_value => attributes[k],
                                                                :value => v)       
      end
    end
    journal.save

    #issue.save!    
  end
   
  def save_issues(simulation = false)
    load_book if self.book.nil?
    issue_template = build_issue_template
    custom_fields_formats
    time_entries = []
    result = {}
    
 
    #Issue.transaction do
      book.first_data_row.upto(book.last_row) do |index|
        row = load_row(index)
        issue_mapping = build_complete_mapping(row, issue_template)
        issue = load_or_create_issue(issue_mapping)
        result[row] = build_log_for_row(issue)
        time_entries = create_time_entries(row) if self.has_time_entry?
        
        #unless simulation
          # Obtenemos la diferencia de attributos
        #end
        #save_issue_with_journal(issue)
        #issue.attributes = issue_mapping
        if issue.save
          create_journal(issue)
          save_time_entries(time_entries, issue.id)
        end
      end      
    #end
    save_log(result)
  end
  
  def save_time_entries(time_entries, issue_id)
    time_entries.each do |t|
      t.issue_id = issue_id
      t.save
    end
  end
  
  def validate_process
    load_book if self.book.nil?
    issue_template = build_issue_template
    custom_fields_formats
    time_entries = []
    result = {}
   
    book.first_data_row.upto(book.last_row) do |index|
      row = load_row(index)
      issue_mapping = build_complete_mapping(row, issue_template)
      issue = load_or_create_issue(issue_mapping)
      time_entries = create_time_entries(row) if self.has_time_entry?

      #puts issue.inspect
      result[index] = build_log_for_row(issue, time_entries)
    end  
           
    save_log(result)       
  end
  
  def build_log_for_row(issue, time_entries = [])  
    t_result = build_log_for_time_entries(time_entries)
    {
        'valid' => issue.valid? && t_result['valid'],
        'errors' => issue.errors.full_messages,
        'time_entry_errors' => t_result['errors'],
        'new' => issue.new_record?
    } 
  end
  
  def build_log_for_time_entries(time_entries = [])
    result = {
        'valid' => true,
        'errors' => [],     
    }
    time_entries.each do |te|
      unless te.valid?
        result['valid'] = false
        result['errors'] = (result['errors'] + te.errors.full_messages).flatten.uniq
      end
    end
    result
  end
  
  def log_is_ok?
    self.log.detect {|entry| entry.last["valid"] == false}.nil?
  end
  
  def save_log(result)
    self.log = result
    save
  end
  
  def done!
    self.status = 'done'
    save
  end
    
  def required_fields
    ["subject", "priority_id", "status_id"] + (project.issue_custom_fields & tracker.custom_fields).select {|cf| cf.is_required?}.map{|cf| cf.id.to_s}
  end
  
  def all_required_fields_are_mapped?
     (required_fields - fields.keys).empty?
  end
  
  def fields_with_format  
    fields.each do |field, mapping|
      if field.to_i == 0
        mapping["format"] = 'core'
      else
        cf = CustomField.find(field.to_i)
        mapping['format'] = cf.nil? ? '' : cf.field_format
      end 
    end
    fields  
  end
  
  def total_rows
    load_book if self.book.nil?
    self.book.last_row - 1 # one row less because first row contains headers
  end

  
  #private
  def load_book(reload = false)
    if reload or self.book.nil?
      self.book = ImportIssuesEngine::Book.new 
      self.book.load_file(self.attachments.first.diskfile)
    end
  end
  
  def custom_fields_formats
    @@formats = {}
    self.fields.reject{|k,v| k.to_i == 0}.each {|cf, meta|
      custom_field = CustomField.find(cf.to_i)
      @@formats[cf] = {}
      @@formats[cf]["format"] = ""
      if custom_field
        @@formats[cf]["format"] = custom_field.field_format
        @@formats[cf]["multiple"] = custom_field.multiple
      end 
      }
    @@formats
  end
  
  def set_default_info
    self.status = 'in_progress'
    self.created_at = Time.now
  end
  
  def check_fields
    self.fields = self.fields.select {|k, v| v["source"] != "ignore"}
    self.fields = self.fields.select {|k, v| v["value"].present?}
    self.time_entry_fields = self.time_entry_fields.select {|k, v| v["source"] != "ignore"}
    self.time_entry_fields = self.time_entry_fields.select {|k, v| v["value"].present?}    
  end
  
  def has_time_entry?
    self.time_entry_fields.any?
  end
  
  def build_issue_template
    issue_template = {
      "project_id" => self.project.id,
      "tracker_id" => self.tracker.id,
      "author_id" => User.current.id,
      "custom_field_values" => custom_fields_mapping_from_redmine
    }.merge(core_fields_mapping_from_redmine)    
  end
  
  def create_time_entries(file_row, issue_id = nil)
    time_entries = []
    t = {:issue_id => issue_id}
    #puts file_row
    self.time_entry_fields.each do |time_field, mapping|
      puts mapping
      value = (mapping["source"] == "redmine" ? mapping["value"] : file_row[mapping["value"].to_i][:value])
      value = value.to_f if ["hours", "activity_id"].include?(time_field)
      value = value.split('|') if time_field.to_sym == :users
      t[time_field.to_sym] = value
    end
    t[:users] = [User.current.id] unless t.has_key?(:users)
    t.delete(:users).each do |user|
      #puts t
      ttmp = TimeEntry.new(t)
      ttmp.project_id = self.project_id
      ttmp.user_id = user.to_i
      time_entries << ttmp
    end
    time_entries
  end
  
  def build_complete_mapping(file_row, issue_template = nil)
    issue_template ||= self.build_issue_template
    new_issue = issue_template
    tmp = core_fields_mapping_from_file
    tmp.each{ |t,v|
       tmp[t] = get_core_value(t, file_row[v.to_i])
    }
    new_issue.merge!(tmp)
    
    tmp = custom_fields_mapping_from_file
    tmp.each{ |t,v|
       tmp[t] = get_value_with_format_from_file(t, v, file_row)
    }    
    new_issue["custom_field_values"].merge!(tmp)    
    new_issue
  end
  
  def get_value_with_format_from_file(t, v, file_row)
    format = @@formats[t]["format"] if @@formats[t]   
    format ||= "string"
    accept_multiple = (["user","version","list"].include?(format) && @@formats[t]["multiple"])
    value = file_row[v.to_i][:value].to_s
    
    if format == "string" && file_row[v.to_i][:format] == :float
      value = value.to_i.to_s
    elsif format == "int" && file_row[v.to_i][:format] == :float
      value = value.to_i.to_s
    elsif format == "list" && file_row[v.to_i][:format] == :float
      value = value.to_i.to_s
    elsif accept_multiple && file_row[v.to_i][:format] == :string
      value = value.split('|')
      #puts value
    else
      value = value.to_s
    end
    #puts "#{file_row[v.to_i][:format]}: #{value}"
    value         
  end
  
  def create_journal(issue)
    if @current_journal
      # attributes changes
      if @attributes_before_change
        (Issue.column_names - %w(id root_id lft rgt lock_version created_on updated_on closed_on)).each {|c|
          before = @attributes_before_change[c]
          after = issue.send(c)
          next if before == after || (before.blank? && after.blank?)
          @current_journal.details << JournalDetail.new(:property => 'attr',
                                                        :prop_key => c,
                                                        :old_value => before,
                                                        :value => after)
        }
      end
      if @custom_values_before_change
        # custom fields changes
        issue.custom_field_values.each {|c|
          before = @custom_values_before_change[c.custom_field_id]
          after = c.value
          next if before == after || (before.blank? && after.blank?)
          
          if before.is_a?(Array) || after.is_a?(Array)
            before = [before] unless before.is_a?(Array)
            after = [after] unless after.is_a?(Array)
            
            # values removed
            (before - after).reject(&:blank?).each do |value|
              @current_journal.details << JournalDetail.new(:property => 'cf',
                                                            :prop_key => c.custom_field_id,
                                                            :old_value => value,
                                                            :value => nil)
            end
            # values added
            (after - before).reject(&:blank?).each do |value|
              @current_journal.details << JournalDetail.new(:property => 'cf',
                                                            :prop_key => c.custom_field_id,
                                                            :old_value => nil,
                                                            :value => value)
            end
          else
            @current_journal.details << JournalDetail.new(:property => 'cf',
                                                          :prop_key => c.custom_field_id,
                                                          :old_value => before,
                                                          :value => after)
          end
        }
      end
      @current_journal.save!
      # reset current journal
      init_journal @current_journal.user, issue, @current_journal.notes
    end
  end  
  
  def init_journal(user, issue, notes = "" )
    @current_journal = Journal.new(:journalized => issue, :user => user, :notes => notes)
    @current_journal.notify = false
    @attributes_before_change = issue.attributes.dup
    @custom_values_before_change = {}
    issue.custom_field_values.each {|c| @custom_values_before_change.store c.custom_field_id, c.value }
    @current_journal
  end  
  
  
  def self.carga_afectaciones
    libro = Roo::Openoffice.new('/home/javiferrer/afectaciones.ods')
    
    first_row = 4
    last_row = 357
    last_column = 110
    project_id = nil
    
    first_row.upto(last_row) do |i|
      valor = libro.cell(i,1)
      
      unless valor.nil?
        if valor.to_s[0] == "P"
          project_id = valor.gsub('P','').to_i
        elsif valor == "NN"
          self.guarda_valor_no_planificado(libro, i, project_id)
        else
          self.guarda_valor_planificado(libro, i, project_id)
        end
      end
    end
  end


  def self.guarda_valor_no_planificado(libro, i, project_id)
    user_id = libro.cell(i,1)
    notes = libro.cell(i, 3)
    metier = libro.cell(i, 5)
    metier_id = headcount_role(metier)
    initial_column = 6
    init_date = Date.new(2014,6,30) - initial_column.days
    
    initial_column.upto(110) do |c|
      aff = libro.cell(i, c)
      
      unless aff.nil?
        HeadcountUnplanned.create(:project_id => project_id, :notes => notes, :metier_id => metier_id, :affectation => 'NN', 
        :date_on => (init_date + c.days))
      end
    end
  end


  
  def self.guarda_valor_planificado(libro, i, project_id)
    user_id = libro.cell(i,1)
    notes = libro.cell(i, 3)
    metier = libro.cell(i, 5)
    metier_id = headcount_role(metier)
    initial_column = 6
    init_date = Date.new(2014,6,30) - initial_column.days
    
    initial_column.upto(110) do |c|
      aff = libro.cell(i, c)
      
      unless aff.nil?
        Headcount.create(:project_id => project_id, :notes => notes, :metier_id => metier_id, :affectation => aff, 
        :date_on => (init_date + c.days), :user_id => user_id.to_i)
      end
    end
  end
  
  def self.headcount_role(h)
    m = HeadcountRole.find_by_name(h)
    m = HeadcountRole.create(:name => h) if m.nil?
    m.id
  end
end
