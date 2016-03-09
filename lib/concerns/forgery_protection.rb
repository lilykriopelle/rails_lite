require 'active_support/concern'

module ForgeryProtection
  extend ActiveSupport::Concern

  @@forgery_protection = {}

  class_methods do
    def protect_from_forgery(options)
      @@forgery_protection = options
    end
  end

  def form_authenticity_token
    token = SecureRandom::urlsafe_base64
    flash[:csrf_tokens] ||= []
    flash[:csrf_tokens] << token
    token
  end

  private
  def check_csrf(name)
    if @@forgery_protection[:with] == :exception
      if [:create, :update, :destroy].include?(name) && !valid_csrf_token_present?
        raise "Invalid authenticity token."
      end
    end
  end

  def valid_csrf_token_present?
    flash["csrf_tokens"] && flash["csrf_tokens"].include?(req.params["authenticity_token"])
  end
end
