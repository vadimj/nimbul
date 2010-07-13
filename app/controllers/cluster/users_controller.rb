class Cluster::UsersController < ApplicationController
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_cluster_access?(Cluster.find(params[:cluster_id]))"

    def create
        @cluster = Cluster.find(params[:cluster_id])
        begin
            @user = User.find(params[:user][:id])
            @included = @user.has_cluster_access?(@cluster)
        rescue
            @error = "Couldn't find a user with id: #{params[:user][:id]}."
            flash[:error] = @error
        end

        respond_to do |format|
			if !@user.nil? and (@included or (@cluster.users << @user))
				flash[:notice] = "Granted Cluster Admin to '#{@user.name}'."
                format.html { redirect_to @cluster }
                format.xml  { head :ok }
                format.js
			else
                format.html { redirect_to @cluster }
				format.xml  { render :xml => @cluster.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end

    def destroy
        @cluster = Cluster.find(params[:cluster_id])
        @user = User.find(params[:id])        

        respond_to do |format|
			if !@user.nil? and @cluster.users.delete(@user)
				flash[:notice] = "Revoked Cluster Admin from '#{@user.name}'."
                format.html { redirect_to @cluster }
                format.xml  { head :ok }
                format.js
			else
				format.html { render :action => "edit" }
				format.xml  { render :xml => @cluster.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end

end

