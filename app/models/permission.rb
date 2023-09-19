class Permission < ApplicationRecord
  PERMITS = %i[read edit delete transfer grant revoke]
  belongs_to :user
  belongs_to :permissable, polymorphic: true

  def permits!(permits)
    byebug
    permits = [*permits].map { |p| p.to_sym }
    self.permissions_mask = (permits & PERMITS).map { |p| 2**PERMITS.index(p) }.inject(0, :+)
  end

  def permits
    PERMITS.reject do |p|
      (permissions_mask & 2**PERMITS.index(p)).zero?
    end
  end
end
