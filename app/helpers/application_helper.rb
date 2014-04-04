module ApplicationHelper
  def cdn_path file_path
    if Rails.env.production? || Rails.env.staging?
      if Settings.use_cloud_front
        Settings.cloud_front.endpoint_url + file_path
      else
        Settings.s3.endpoint_url + file_path
      end
    else
      file_path
    end
  end
end
