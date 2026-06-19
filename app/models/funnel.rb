class Funnel < ApplicationRecord
  belongs_to :account
  has_many :kanban_items, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :stages, presence: true
  validate :stages_have_ids

  scope :active, -> { where(active: true) }
  scope :ordered_by_name, -> { order(:name) }

  def stage_ids
    stages.pluck('id')
  end

  private

  def stages_have_ids
    return if stages.blank?

    stages.each_with_index do |stage, index|
      errors.add(:stages, "stage #{index + 1} is missing an id") if stage['id'].blank?
    end
  end
end
