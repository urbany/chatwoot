class Api::V1::Accounts::FunnelsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :fetch_funnel, except: [:index, :create]

  def index
    authorize(Funnel)
    @funnels = Current.account.funnels.active.ordered_by_name
  end

  def show
    authorize(@funnel)
  end

  def create
    authorize(Funnel)
    @funnel = Current.account.funnels.new(funnel_params)
    @funnel.save!
  end

  def update
    authorize(@funnel)
    @funnel.update!(funnel_params)
  end

  def destroy
    authorize(@funnel)
    @funnel.destroy!
    head :ok
  end

  private

  def fetch_funnel
    @funnel = Current.account.funnels.find(params[:id])
  end

  def funnel_params
    params.require(:funnel).permit(:name, :description, :active, stages: [%i[id name color]])
  end
end
