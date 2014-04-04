class User < ActiveRecord::Base
  def update_with_omniauth(auth)
    self.update_attributes!({
      provider:   auth['provider'],
      uid:        auth['uid'],
      name:       auth['info']['name'],
    })
  end
end
