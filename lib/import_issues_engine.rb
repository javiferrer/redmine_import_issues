require 'rubygems'
require 'roo'

module ImportIssuesEngine
  
  SOURCES = ['ignore', 'file', 'redmine']
  
  class Book
    attr_accessor :file
    
    def load_file(filename)
      extension = filename[-3,3].downcase.to_sym
      
      begin
        open_with_xls(filename) if extension == :xls
        open_with_xlsx(filename) if extension == :lsx
        open_with_ods(filename) if extension == :ods
      rescue
        raise  ErrorLoadingFile, "Error leyendo el fichero" 
      end      
      !!self.file.nil?
    end
        
    def headers
      h = []
      1.upto(file.last_column) do |header|
        h << [file.cell(1,header), header]
      end
      h
    end
    
    def self.check_file(filename)
      extension = filename[-3,3].downcase.to_sym
      [:xls, :lsx, :ods].include?(extension)
    end  
    
    def first_column
      file.first_column
    end
    
    def first_row
      file.first_row
    end
    
    def first_data_row
      file.first_row + 1
    end
    
    def last_column
      file.last_column
    end 
    
    def last_row
      file.last_row
    end
    
    def load_row(row_line)
      row = {}
      file.first_column.upto(file.last_column) do |column|
        row[column] = {
          :value => file.cell(row_line, column),
          :format => file.celltype(row_line, column)
        }
      end
      row
    end
    
    private
    def open_with_xls(filename)
      self.file = Roo::Excel.new(filename)
    end

    def open_with_ods(filename)
      self.file = Roo::Openoffice.new(filename)
    end

    def open_with_xlsx(filename)
      self.file = Roo::Excelx.new(filename)
    end
    
  end 
  
  class ErrorLoadingFile < StandardError
  end  
end
