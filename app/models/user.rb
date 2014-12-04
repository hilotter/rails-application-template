class User < ActiveRecord::Base
  def self.find_or_create_from_auth_hash(auth_hash)
    provider = auth_hash[:provider]
    uid = auth_hash['uid']
    name = auth_hash['info']['name']

    User.find_or_create_by(provider: provider, uid: uid) do |user|
      user.name = name
    end
  end
end
