class AppPermit < ApplicationRecord
  PERMITS = %i[read edit delete transfer grant revoke]
  belongs_to :user
  belongs_to :app

  def permits!(permits)
    byebug
    permits = [*permits].map { |p| p.to_sym }
    self.permissions_mask = (permits & PERMISSIONS).map { |p| 2**PERMISSIONS.index(p) }.inject(0, :+)
  end

  def permits
    PERMISSIONS.reject do |p|
      (permissions_mask & 2**PERMISSIONS.index(p)).zero?
    end
  end
end
