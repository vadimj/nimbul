class Instance::ConsoleOutputController < ApplicationController
	before_filter :login_required
	require_role  :admin,
        :unless => "params[:id].nil? or current_user.has_instance_access?(Instance.find(params[:id])) "

	def show
		@instance = Ec2Adapter.get_console_output(Instance.find(params[:id]))
        respond_to do |format|
            format.html
            format.js  { render :partial => 'output', :layout => false }
        end
	end
end
