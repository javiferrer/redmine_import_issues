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

class ImportIssuesController < ApplicationController
  unloadable

  before_filter :find_project_by_project_id
  before_filter :authorize
  
  
  helper :custom_fields
  include CustomFieldsHelper  
  helper :attachments
  include AttachmentsHelper
  include TimelogHelper
  
  def index
    @import = ImportAction.new
    @trackers = @project.trackers
    @templates = ImportAction.load_templates(@project)
    @in_progress = [] # ImportAction.load_in_progress
  end
  
  def create
    if params[:attachments].present?
      @import = ImportAction.new(params[:import])
      @import.project = @project
      @import.user = User.current
      @import.save_attachments(params[:attachments])
      @import.save
      
      if @import.check_file      
        redirect_to prepare_project_import_issue_path(@project, @import)
      else
        flash[:error] = l(:error_file_incorrect)
        redirect_to project_import_issues_path(@project)
      end
    else
      flash[:error] = l(:error_file_mandatory)
      redirect_to project_import_issues_path(@project)
    end    
  end
  
  def update
    @import = ImportAction.find(params[:id])
    @import.issue_fields = params[:fields]
    @import.time_entries_fields = params[:time_entry]
    @import.field_for_update = params[:options][:field_for_update] || nil
    @import.is_template = params[:options][:save_as_template] == "1"
    
    if @import.is_template?
      @import.name = params[:options][:template_name] || ""
      @import.description = params[:options][:template_description] || ""
    end
    @import.save
    
    if @import.all_required_fields_are_mapped?
      redirect_to overview_project_import_issue_path(@project, @import)
    else
      flash[:error] = l(:error_all_required_filled_not_mapped)
      redirect_to prepare_project_import_issue_path(@project, @import)
    end
  end
  
  def recover
    template = ImportAction.find(params[:id])
    @import = template.dup
    @import.is_template = false
    @import.template_id = template.id
    @import.user = User.current
    @import.save
  end  

  def prepare
    @import = ImportAction.find(params[:id])
    @statuses = @import.tracker.issue_statuses
    @columns = @import.headers
    @sources = ImportIssuesEngine::SOURCES  
    @fields_for_update = @import.custom_fields.select {|cf| cf.field_format == 'string'}   #<< ["id", "ISSUE ID"]
    @fields_for_time_entry = ImportAction::TIME_ENTRY_FIELDS  
    @time_entry = TimeEntry.new(:project => @project)
  end
  
  def overview
    @import = ImportAction.find(params[:id])
  end

  def validate
    @import = ImportAction.find(params[:id])
    @import.validate_process    
  end

  def import
    @import = ImportAction.find(params[:id])
    @import.save_issues
    
    if @import.log_is_ok?
      flash[:notice] = l(:label_import_ok)
      @import.done!
      @import.destroy unless @import.is_template?
      redirect_to :action => 'index'
    else
      flash[:error] = l(:label_import_failed)
    end
  end
  
  def load_values_for_field
    @option = params[:option]
    
    @field_id = params[:custom_field_id]
    
    unless @option == "ignore"
      @import = ImportAction.find(params[:id])
      # if custom_field_id is 0, it is a core field
      if params[:custom_field_id].to_i == 0
        @core_field = params[:custom_field_id].to_s
        @field_id = @core_field
        @name_of_field = @core_field
        
        @format = "date" if ['start_date', 'due_date', 'spent_on'].include?(@core_field)
      else
        @custom_field = CustomField.find(params[:custom_field_id])
        @custom_value = CustomValue.new({:custom_field => @custom_field, :customized => Issue.new(:tracker => @import.tracker, :project => @import.project)})
        @field_id =  @custom_field.id
        @format = @custom_field.field_format 
        @name_of_field = @custom_field.name
      end
      
      
      if @option == "file"
        @headers = ImportAction.find(params[:id]).headers 
        tmp_search = @headers.select {|h| h.first.upcase == @name_of_field.upcase}.flatten
        @selected_header = 0
        if tmp_search.any?
          @selected_header = tmp_search.last
        end        
      end
    end
    
    respond_to do |format|
      format.js
    end
  end
  
  def load_values_for_time_entry
    @option = params[:option]
    
    @field_id = params[:custom_field_id]
    
    unless @option == "ignore"
      @import = ImportAction.find(params[:id])
      # if custom_field_id is 0, it is a core field
      if params[:custom_field_id].to_i == 0
        @core_field = params[:custom_field_id].to_s
        @field_id = @core_field
        @name_of_field = @core_field
        
        @format = "date" if ['spent_on'].include?(@core_field)
      end
      
      
      if @option == "file"
        @headers = ImportAction.find(params[:id]).headers 
        tmp_search = @headers.select {|h| h.first.upcase == @name_of_field.upcase}.flatten
        @selected_header = 0
        if tmp_search.any?
          @selected_header = tmp_search.last
        end        
      end
    end
    
    respond_to do |format|
      format.js
    end
  end  
  
  def download
    @import = ImportAction.find(params[:id])
    file = @import.attachments.last
    send_file file.diskfile, :filename => filename_for_content_disposition(file.filename),
                                    :type => detect_content_type(file),
                                    :disposition => (file.image? ? 'inline' : 'attachment')    
  end
  
  def change_file_recover
    @import = ImportAction.find(params[:id])
    if params[:attachments].present?
      
      @import.save_attachments(params[:attachments])
      @import.save  
      
      if @import.attachments.count > 1
        @import.attachments.first.destroy
      end
      
      if !@import.check_file
        flash[:error] = l(:error_file_incorrect)
        redirect_to recover_project_import_issue_path(@project, @import)
      else      
        redirect_to overview_project_import_issue_path(@project, @import)
      end 
    else
      flash[:error] = l(:error_file_mandatory)
      redirect_to recover_project_import_issue_path(@project, @import)
    end  
  end
  
  def change_file
    change_file_process
    
    redirect_to :action => 'prepare', :id => @project, :import_id => @import    
  end  
  
  def destroy
    @import = ImportAction.find(params[:id])
    
    @import.destroy
  
    flash[:notice] = l(:label_import_deleted)
    redirect_to :action => 'index'    
  end
  
  
  private 
  def load_import
    @import = ImportAction.find(params[:id])
  end
  
  def change_file_process
    @import = ImportAction.find(params[:id])
    if params[:attachments].present?
      
      @import.save_attachments(params[:attachments])
      @import.save  
      
      if @import.check_file
        @import.attachments.first.destroy if @import.attachments.count > 1
      else
        @import.attachments.last.destroy if @import.attachments.count > 1
        flash[:error] = l(:error_file_incorrect)
      end
    end     
  end
  
  def load_fields
    @core_values = {
      'assigned_to_id' => @project.assignable_users,
      'category_id' =>  @project.issue_categories,
      'fixed_version_id' => @project.versions.open,
      'done_ratio' => (0..10).to_a.collect {|r| ["#{r*10} %", r*10] }      
    }
  end
  
  def detect_content_type(attachment)
    content_type = attachment.content_type
    if content_type.blank?
      content_type = Redmine::MimeType.of(attachment.filename)
    end
    content_type.to_s
  end  
end
