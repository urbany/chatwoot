class KanbanItem < ApplicationRecord
  belongs_to :account
  belongs_to :funnel
  belongs_to :conversation, foreign_key: :conversation_display_id,
                            primary_key: :display_id, class_name: 'Conversation', optional: true,
                            inverse_of: :kanban_items

  validates :funnel_stage, :position, presence: true
  validate :stage_exists_in_funnel

  scope :ordered, -> { order(:position, :created_at) }
  scope :for_stage, ->(stage) { where(funnel_stage: stage) }

  delegate :stages, to: :funnel

  private

  def stage_exists_in_funnel
    return if funnel.blank? || funnel.stage_ids.include?(funnel_stage)

    errors.add(:funnel_stage, 'is not a valid stage for this funnel')
  end
end
