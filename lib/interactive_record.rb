require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  def self.table_name
    self.name.downcase.pluralize
  end

  def table_name_for_insert
    self.class.name.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end
    column_names
  end

  def col_names_for_insert
    self.class.column_names.delete_if { |col| col == "id" }.join(", ")
  end

  def initialize(options={})
    options.each do |property, values|
      self.send("#{property}=", values)
    end
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col_names|
      values << "'#{send(col_names)}'" unless send(col_names).nil?
    end
    values.join(", ")
  end

  def save
    sql = "INSERT INTO #{self.table_name_for_insert} (#{self.col_names_for_insert}) VALUES (#{self.values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE '#{name}' = name"
    DB[:conn].execute(sql)
  end

  def self.find_by(attribute_hash)
    value = attribute_hash.values.first
    if value.is_a? Fixnum
      sql = "SELECT * FROM #{self.table_name} where #{value} = #{attribute_hash.keys.first}"
    else
      sql = "SELECT * FROM #{self.table_name} where '#{value}' = #{attribute_hash.keys.first}"
    end
    DB[:conn].execute(sql)
  end

end
