class ProviderAccount::UsersController < ApplicationController
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_provider_account_access?(ProviderAccount.find(params[:provider_account_id])) "

    def create
        @provider_account = ProviderAccount.find(params[:provider_account_id])
        begin
            @user = User.find(params[:user][:id])
            @included = @provider_account.users.include?(@user)
        rescue
            @error = "Couldn't find a user with id: #{params[:user][:id]}."
            flash[:error] = @error
        end

        respond_to do |format|
			if !@user.nil? and (@included or (@provider_account.users << @user))
				flash[:notice] = "Granted Provider Account Admin to '#{@user.name}'."
                format.html { redirect_to @provider_account }
                format.xml  { head :ok }
                format.js
			else
                format.html { redirect_to @provider_account }
				format.xml  { render :xml => @provider_account.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end

    def destroy
        @provider_account = ProviderAccount.find(params[:provider_account_id])
        @user = User.find(params[:id])        

        respond_to do |format|
			if !@user.nil? and @provider_account.users.delete(@user)
				flash[:notice] = "Revoked Provider Account Admin from '#{@user.name}'."
                format.html { redirect_to @provider_account }
                format.xml  { head :ok }
                format.js
			else
				format.html { render :action => "edit" }
				format.xml  { render :xml => @provider_account.errors, :status => :unprocessable_entity }
				format.js
			end
        end
    end

end

