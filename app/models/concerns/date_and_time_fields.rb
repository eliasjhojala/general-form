module DateAndTimeFields
  extend ActiveSupport::Concern
  
  included do
    def self.date_and_time_fields *fields
      fields.each do |field|
        attr_reader :"#{field}_at_date", :"#{field}_time"

        [:date, :time].each do
          alias_attribute :"#{field}_#{_1}", field
        end

        define_method :"#{field}_date=" do |date|
          return unless date.present?
          self[field] = (self[field] || Time.now).change **[:year, :month, :day].to_h { [_1, Date.parse(date).send(_1)] }
        end

        define_method :"#{field}_time=" do |time|
          return unless time.present?
          self[field] = (self[field] || Time.now).change **[:hour, :min, :sec].to_h { [_1, Time.parse(time).send(_1)] }
        end
      end
    end
  end

end
