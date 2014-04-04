class SessionsController < BaseController
  def callback
    auth = request.env['omniauth.auth']

    ActiveRecord::Base.transaction do
      user = User.find_or_create_by(provider: auth['provider'], uid: auth['uid'])
      raise 'can not get user' if !user
      user.update_with_omniauth(auth)
      session[:user_id] = user.id
    end

    redirect_to root_path
  end

  def destroy
    reset_session
    redirect_to root_path
  end

  def failure
    return redirect_to root_path
  end

end

