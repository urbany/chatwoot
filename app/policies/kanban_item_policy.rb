class KanbanItemPolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || @account_user.agent?
  end

  def show?
    index?
  end

  def create?
    index?
  end

  def update?
    index?
  end

  def destroy?
    @account_user.administrator?
  end

  def move?
    update?
  end

  def reorder?
    update?
  end
end
