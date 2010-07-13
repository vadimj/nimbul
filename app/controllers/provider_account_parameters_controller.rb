class ProviderAccountParametersController < ApplicationController
    # POST /provider_account_parameters
    # POST /provider_account_parameters.xml
    def create
        @provider_account = ProviderAccount.find(params[:provider_account_id])
        redirect_url = url_for(
                    :id => @provider_account.id,
                    :controller => 'provider_accounts',
                    :action => 'show',
                    :anchor => 'variables')
        @provider_account.provider_account_parameter_attributes = params[:provider_account][:provider_account_parameter_attributes]
        respond_to do |format|
            if @provider_account.save_provider_account_parameters
                flash[:notice] = 'Account Variables were successfully updated.'
                format.html { redirect_to redirect_url }
                format.xml  { render :xml => @provider_account, :status => :updated, :location => @provider_account }
            else
                flash[:error] = 'Failed to update Account Variables.'
                format.html { redirect_to redirect_url }
                format.xml  { render :xml => @provider_account.errors, :status => :unprocessable_entity }
            end
        end
    end

    def sort
        params[:provider_account_parameters].each_with_index do |id, index|
            ProviderAccountParameter.update_all(['position=?', index+1], ['id=?', id])
        end
        render :nothing => true
    end
end
