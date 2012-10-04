require 'memoryleak'

class ApplicationController < ActionController::Base
  protect_from_forgery

  helper :all

  rescue_from ArchivesSpace::SessionGone, :with => :destroy_user_session


  # Note: This should be first!
  before_filter :store_user_session

  before_filter :refresh_permissions

  before_filter :load_repository_list
  before_filter :load_default_vocabulary

  before_filter :sanitize_params

  protected

  def inline?
    params[:inline] === "true"
  end


  # Perform the common create/update logic for our various CRUD controllers:
  #
  #  * Take user parameters and massage them a bit
  #  * Grab the existing instance of our JSONModel
  #  * Update it from the parameters
  #  * If all looks good, send the user off to their next adventure
  #  * Otherwise, throw the form back with warnings/errors
  #
  def handle_crud(opts)
    begin

      # The UI may pass JSON blobs for linked resources for the purposes of displaying its form.
      # Deserialise these so the corresponding objects are stored on the JSONModel.
      (params[opts[:instance]]["resolved"] or []).each do |property, value|
        values =  value.collect {|json| JSON(json) if json and not json.empty?}.reject {|e| e.nil?}
        params[opts[:instance]]["resolved"][property] = values
      end

      # Start with the JSONModel object provided, or an empty one if none was
      # given.  Update it from the user's parameters
      model = opts[:model] || JSONModel(opts[:instance])
      obj = opts[:obj] || model.new


      fix_arrays = proc do |hash, schema|
        result = hash.clone

        schema['properties'].each do |property, definition|
          if definition['type'] == 'array' and result[property].is_a?(Hash)
            result[property] = result[property].sort_by {|k, _| k}.map {|_, v| v}
          end
        end

        result
      end


      instance = JSONModel(opts[:instance]).map_hash_with_schema(params[opts[:instance]],
                                                                 nil,
                                                                 [fix_arrays])

      if opts[:replace] || opts[:replace].nil?
        obj.replace(instance)
      else
        obj.update(instance)
      end

      # Make the updated object available to templates
      instance_variable_set("@#{opts[:instance]}".intern, obj)

      if not params.has_key?(:ignorewarnings) and not obj._warnings.empty?
        # Throw the form back to the user to confirm warnings.
        return opts[:on_invalid].call
      end

      id = obj.save
      opts[:on_valid].call(id)
    rescue JSONModel::ValidationException => e
      # Throw the form back to the user to display error messages.
      opts[:on_invalid].call
    end
  end


  helper_method :user_can?
  def user_can?(permission, repository = nil)
    repository ||= session[:repo]

    (session &&
     session[:user] &&
     session[:permissions] &&

     ((session[:permissions][repository] &&
       session[:permissions][repository].include?(permission)) ||

      (session[:permissions]['_archivesspace'] &&
       session[:permissions]['_archivesspace'].include?(permission))))
  end



  private

  def destroy_user_session
    Thread.current[:backend_session] = nil
    Thread.current[:repo_id] = nil

    reset_session

    flash[:error] = "Your backend session was not found"
    redirect_to :controller => :welcome, :action => :index
  end


  def store_user_session
    Thread.current[:backend_session] = session[:session]
    Thread.current[:selected_repo_id] = session[:repo_id]
  end


  def load_repository_list
    unless request.path == '/webhook/notify'
      @repositories = MemoryLeak::Resources.get(:repository).find_all do |repository|
        user_can?('view_repository', repository.repo_code) || user_can?('manage_repository', repository.repo_code)
      end

      # Make sure the user's selected repository still exists.
      if session[:repo] && !@repositories.any?{|repo| repo.repo_code == session[:repo]}
        session.delete(:repo)
        session.delete(:repo_id)
      end

      if not session[:repo] and not @repositories.empty?
        session[:repo] = @repositories.first.repo_code.to_s
        session[:repo_id] = @repositories.first.id
      end
    end
  end


  def refresh_permissions
    unless request.path == '/webhook/notify'
      if session[:last_permission_refresh] &&
          session[:last_permission_refresh] < MemoryLeak::Resources.get(:acl_last_modified)
        User.refresh_permissions(session)
      end
    end
  end


  def choose_layout
    if inline?
      nil
    else
      'application'
    end
  end


  def sanitize_param(hash)
    hash.clone.each do |k,v|
      hash[k.sub("_attributes","")] = v if k.end_with?("_attributes")
      sanitize_param(v) if v.kind_of? Hash
    end
  end


  def load_default_vocabulary
    unless request.path == '/webhook/notify'
      session[:vocabulary] = MemoryLeak::Resources.get(:vocabulary).first.to_hash
    end
  end

  def sanitize_params
    sanitize_param(params)
  end

end
