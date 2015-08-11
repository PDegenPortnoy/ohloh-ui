module ActsAsTaggable
  extend ActiveSupport::Concern

  module ClassMethods
    def acts_as_taggable
      has_many :taggings, as: :taggable, dependent: :destroy
      has_many :tags, through: :taggings

      attr_accessor :tag_list_is_dirty

      include ActsAsTaggable::InstanceMethods
    end
  end

  module InstanceMethods
    def tag_list=(list)
      return if tag_list == list
      self.tag_list_is_dirty = true
      self.tags = parse_tag_list(list).map { |tag| Tag.where(name: tag).first_or_create }
    end

    def tag_list
      tags.pluck(:name).uniq.compact.join(' ')
    end

    private

    def parse_tag_list(list)
      return [] if list.blank?
      list.gsub(/\"/, '').split(/\s/).reject(&:blank?)
    end
  end
end

ActiveRecord::Base.send :include, ActsAsTaggable
