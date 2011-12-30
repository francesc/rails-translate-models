module RailsTranslateModels
  def has_translations(*args)
    # store options
    cattr_accessor :has_translations_options
    self.has_translations_options = args

    # create translations class
    type = self.to_s.underscore
    translations_klass_name = "#{self}_translation".classify
    translations_table_name = translations_klass_name.pluralize.tableize.to_sym

    translations_klass = Class.new(ActiveRecord::Base) do
      set_table_name translations_table_name
      belongs_to type.to_sym
      validates_presence_of type.to_sym, :language_code
      validates_uniqueness_of :language_code, :scope => "#{type}_id"
    end

    Object.const_set(translations_klass_name, translations_klass)

    # set translations association, scoping, and after_save
    has_many :translations, :class_name => translations_klass_name, :dependent => :destroy
    default_scope :include => :translations

    after_save :store_translated_attributes

    # include methods
    include InstanceMethods
  end

  module InstanceMethods
    def translatable?
      true
    end

    def self.included(base)
      attributes = base.has_translations_options

      attributes.each do |attribute|
        base.class_eval <<-GETTER_AND_SETTER
         def get_#{attribute}(locale=nil)
           get_translated_attribute(locale, :#{attribute})
         end

         def set_#{attribute}(value, locale=I18n.locale)
           set_translated_attribute(locale, :#{attribute}, value)
         end

         alias #{attribute} get_#{attribute}
         alias #{attribute}= set_#{attribute}
       GETTER_AND_SETTER
      end
    end

    def get_translated_attribute(locale, attribute)
      translated_value = if locale
        translated_attributes_for(locale)[attribute]
      else
        # find translated attribute, first try current locale, then english
        text = translated_attributes_for(I18n.locale)[attribute] || translated_attributes_for("en")[attribute]
      end
    end

    def set_translated_attribute(locale, attribute, value)
      old_value = translated_attributes_for(locale)[attribute]
      return if old_value.to_s == value.to_s
      changed_attributes.merge!("#{attribute}_in_#{locale}" => old_value)
      translated_attributes_for(locale)[attribute] = value
      @translated_attributes_changed = true
    end

    def translated_attributes
      return @translated_attributes if @translated_attributes
      merge_db_translations_with_instance_variable
      @translated_attributes ||= {}.with_indifferent_access
    end

    def translated_attributes= hash
      @db_translations_merged = true
      @translated_attributes_changed = true
      @translated_attributes = hash.with_indifferent_access
    end

    def respond_to?(name, *args)
      return true if parse_translated_attribute_method(name)
      super
    end

    def method_missing(name, *args)
      attribute, locale = parse_translated_attribute_method(name)
      return super unless attribute
      if name.to_s.include? '='
        send("set_#{attribute}", args[0], locale)
      else
        send("get_#{attribute}", locale)
      end
    end

    protected

    def store_translated_attributes
      return true unless @translated_attributes_changed
      @translated_attributes.each do |locale, attributes|
        translation = translations.find_or_initialize_by_language_code(locale.to_s)
        translation.attributes = translation.attributes.merge(attributes)
        translation.save!
      end
      @translated_attributes_changed = false
      true
    end

    private

    def merge_db_translations_with_instance_variable
      return if new_record? or @db_translations_merged
      @db_translations_merged = true

      translations.each do |t|
        has_translations_options.each do |attribute|
          translated_attributes_for(t.language_code)[attribute] = eval("t.#{attribute.to_s}")
        end
      end
    end

    def translated_attributes_for(locale)
      translated_attributes[locale] ||= {}.with_indifferent_access
      translated_attributes[locale]
    end

    def parse_translated_attribute_method(name)
      return false if name.to_s !~ /^([a-zA-Z_]+)_in_([a-z]{2})[=]?$/
      attribute = $1; locale = $2
      return false unless is_translated_attribute?(attribute)
      return attribute, locale
    end

    def is_translated_attribute?(method_name)
      attributes = self.class.has_translations_options
      attributes.include? method_name.sub('=','').to_sym
    end
  end
end

ActiveRecord::Base.extend RailsTranslateModels