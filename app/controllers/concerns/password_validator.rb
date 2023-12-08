# app/validators/password_validator.rb

module PasswordValidator
  extend ActiveSupport::Concern

  private

  def validate_password_strength!
    password = params[:password]

    unless password.match?(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+{}\[\]:;<>,.?~\\-]).{12,}$/)
      render json: { errors: ['Password must be at least 12 characters long and include at least one lowercase letter, one uppercase letter, one digit, and one symbol/special character'] }, status: :unprocessable_entity
    end
  end
end
