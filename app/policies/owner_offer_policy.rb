class OwnerOfferPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def new?
   create?
  end

  def create?
    user.owners.pluck(:id).include?(record.owner.id)
  end

  def edit?
    user.owners.pluck(:id).include?(record.owner.id)
  end

  def update?
    edit?
  end

  def add_to_bag?
    true
  end

  def remove_from_bag?
    true
  end

  def increase_to_bag?
    true
  end
end
