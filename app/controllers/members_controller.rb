class MembersController < ApplicationController
	before_filter :login_required

  def index
		@users = User.member_list(params[:page])
	end

	def show
		@user = User.find(params[:id])
	end

end
