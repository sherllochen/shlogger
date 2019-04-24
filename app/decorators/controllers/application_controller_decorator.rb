::ApplicationController.class_eval do
  before_action :set_uuid_session_id

  rescue_from Exception, with: :handle_generic_exception # 可能还有很多其他的异常rescue

  private

  def set_uuid_session_id
    Thread.current[:log_uuid_session_id] = [request.uuid, request.cookie_jar['_session_id']]
  end

  def append_info_to_payload(payload)
    super
    payload[:uuid] = request.uuid
    payload[:session_id] = request.cookie_jar['_session_id']
    payload[:host] = request.host
    payload[:remote_ip] = request.remote_ip
    payload[:origin] = request.headers['HTTP_ORIGIN'].to_s + request.headers['ORIGINAL_FULLPATH']
    payload[:user_agent] = request.headers['HTTP_USER_AGENT']
  end

  # 覆盖通用异常
  def handle_generic_exception(exception)
    log_exception exception, {handler: 'generic_exception'}
    respone_for_exception(exception)
  end

  def log_exception(error, args = {})
    ids = Thread.current[:log_uuid_session_id]
    if error.is_a?(Class) && error <= Exception # 这里是因为有些时候会捕捉到例如RuntimeError这种情况，表示继承自Excpetion
      error_class = error.name
      error_message = error.name
      backtrace = []
    else
      error_class = error.class.name
      error_message = error.message
      backtrace = error.backtrace
    end
    log = {error: error_class, type: 'exception', status: 500, message: error_message, handler: 'log_exception', request_uuid: ids ? ids[0] : '',
           session_id: ids ? ids[1] : '', backtrace: backtrace}.merge({extra_info: args})

    log_json = nil
    begin
      log_json = log.to_json
    rescue
      log[:message] = ''
      log_json = log.to_json
    end
    Rails.logger.error log_json
  end

  def respone_for_exception(exception)
    if api_request?
      render json: {'errors' => exception.message ? exception.message : ''}, status: 422
    else
      redirect_to(request.url != request.referrer ? (request.referrer || root_path) : root_path, notice: exception.message)
    end
  end

  def api_request?
    return request.format.json? || request.env['REQUEST_URI'] =~ /^\/api\//
  end
end