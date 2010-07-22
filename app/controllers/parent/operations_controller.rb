class Parent::OperationsController < ApplicationController
  parent_resources :server, :server_task
  before_filter :login_required
  require_role  :admin, :unless => "current_user.has_access?(parent)"

  def index
    parent.refresh(params[:refresh]) if params[:refresh] and parent.respond_to?('refresh')

		joins = nil
		conditions = nil
    params[:sort] = 'created_at_reverse' if params[:sort].blank?

    @operations = Operation.find_all_by_parent(parent, params[:search], params[:page], joins, conditions, params[:sort], params[:filter])
    @parent_type = parent_type
    @parent = parent

    respond_to do |format|
      format.html
      format.xml  { render :xml => @operations }
      format.js 
    end
  end

  def list
    index
  end

	def show
    @parent = parent
    @parent_type = parent_type
    
    @operation = Operation.find(params[:id], :include => :operation_logs)
    @operation_logs = @operation.operation_logs

    respond_to do |format|
      format.html
      format.xml { render :xml => @operation_logs }
      format.js
    end
	end
end
