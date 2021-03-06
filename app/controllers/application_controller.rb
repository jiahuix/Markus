# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include SessionHandler

  protect_from_forgery  
  
  layout "content"
  
  helper :all # include all helpers, all the time
  
  # activate i18n for renaming constants in views
  before_filter :set_locale, :set_markus_version, :set_remote_user
  # check for active session on every page
  before_filter :authenticate, :except => [:login, :page_not_found] 
  
  # See ActionController::Base for details 
  # Filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "user"). 
  filter_parameter_logging :user
  
  protected
  
  # Set version for MarkUs to be available in
  # any view
  def set_markus_version
    version_file=File.expand_path(File.join(RAILS_ROOT, "app/MARKUS_VERSION"))
    if !File.exist?(version_file)
      @markus_version = "unknown"
      return
    end
    content = File.new(version_file).read
    version_info = Hash.new
    content.split(',').each do |token|
      k,v = token.split('=')
      version_info[k.downcase] = v
    end
    @markus_version = "#{version_info["version"]}.#{version_info["patch_level"]}"
  end
  
  def set_remote_user
    if !request.env["HTTP_X_FORWARDED_USER"].blank?
      @markus_auth_remote_user = request.env["HTTP_X_FORWARDED_USER"]
    end
  end
  
  def set_locale
    # does not do anything for now, but might be used later
    session[:locale] = params[:locale] if params[:locale]
    I18n.locale = session[:locale] || I18n.default_locale # for now, always 
                                                          # resorts to 
                                                          # I18n.default_locale
    
    locale_path = "#{LOCALES_DIRECTORY}#{I18n.locale}.yml"
    
    unless I18n.load_path.include? locale_path
      I18n.load_path << locale_path
      I18n.backend.send(:init_translations)
    end
  
  # handle unknown locales 
  rescue Exception => err
    logger.error err
    flash.now[:notice] = I18n.t("locale_not_available", :locale => I18n.locale)
    
    I18n.load_path -= [locale_path]
    I18n.locale = session[:locale] = I18n.default_locale
  end
end
