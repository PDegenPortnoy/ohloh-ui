class Topic < ActiveRecord::Base
  validates :title, :hits, presence: true
  validates :sticky, :hits, numericality: true
  validates :closed, inclusion: { in: [true, false] }

  belongs_to :account
  belongs_to :forum, counter_cache: true
  has_many :posts, -> { order('created_at asc') }, inverse_of: :topic, dependent: :destroy

  accepts_nested_attributes_for :posts

  scope :recent, -> { where(closed: false).order(replied_at: :desc).limit(10) }
end
