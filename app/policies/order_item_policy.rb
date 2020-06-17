class OrderItemPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def create?
    user_owns_order?
  end

  def destroy?
    user_owns_order?
  end

  private

  def user_owns_order?
    record.order.user == user
  end
end
