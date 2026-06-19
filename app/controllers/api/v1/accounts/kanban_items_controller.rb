class Api::V1::Accounts::KanbanItemsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :fetch_item, only: [:show, :update, :destroy, :move, :reorder]
  before_action :fetch_funnel, only: [:index, :create]

  def index
    authorize(KanbanItem)
    @items = @funnel.kanban_items
    @items = @items.for_stage(params[:stage]) if params[:stage].present?
    @items = @items.ordered
  end

  def show
    authorize(@item)
  end

  def create
    authorize(KanbanItem)
    @item = @funnel.kanban_items.new(item_params.merge(account_id: Current.account.id))
    @item.save!
  end

  def update
    authorize(@item)
    @item.update!(item_params)
  end

  def destroy
    authorize(@item)
    @item.destroy!
    head :ok
  end

  def move
    authorize(@item)
    @item.update!(funnel_stage: params[:funnel_stage], position: params[:position])
  end

  def reorder
    authorize(@item)
    @item.update!(position: params[:position])
  end

  private

  def fetch_item
    @item = Current.account.kanban_items.find(params[:id])
  end

  def fetch_funnel
    funnel_id = params[:funnel_id] || params.dig(:kanban_item, :funnel_id)
    @funnel = Current.account.funnels.find(funnel_id)
  end

  def item_params
    params.require(:kanban_item).permit(
      :funnel_id, :funnel_stage, :position, :conversation_display_id,
      item_details: {}
    )
  end
end
