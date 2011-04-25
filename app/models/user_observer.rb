class UserObserver < ActiveRecord::Observer
  @enabled_changed = false

  def after_save(user)
    UserMailer.deliver_activation(user) if user.recently_activated?
    UserMailer.deliver_forgot_password(user) if user.recently_forgot_password?
    UserMailer.deliver_reset_password(user) if user.recently_reset_password?
    UserMailer.deliver_signup_notification(user) if (user.recently_created? || user.lost_activation_code?)
  end

  def before_update(user)
    @enabled_changed = user.enabled_changed?
    self.class.delete_user_keys_from_servers(user) if @enabled_changed and not user.enabled?
  end

  def after_update(user)
    self.class.add_user_keys_to_servers(user) if @enabled_changed and user.enabled?
  end
  
  def self.delete_user_keys_from_servers(user)
    user.user_keys.each do |user_key|
      UserKeyObserver.delete_user_key_from_servers(user_key)
    end
  end
  
  def self.add_user_keys_to_servers(user)
    user.user_keys.each do |user_key|
      UserKeyObserver.add_user_key_to_servers(user_key)
    end
  end
end
