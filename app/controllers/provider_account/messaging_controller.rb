class ProviderAccount::MessagingController < ApplicationController
  before_filter :login_required
  require_role  :admin,
      :unless => "current_user.has_provider_account_access?(ProviderAccount.find(params[:provider_account_id])) "

  def update
    @provider_account = ProviderAccount.find(params[:provider_account_id])
    msg_params = Hash[params[:provider_account].delete_if{|k,v| not k.to_s.include? 'messaging'}.to_a].symbolize_keys!
    
    @errors = []
    if msg_params[:messaging_uri].blank?
      @errors << "Messaging URI parameter is missing"
    end
    
    redirect_url = provider_account_url(@provider_account, :anchor => params[:anchor])

    respond_to do |format|
      if @errors.size <= 0 and @provider_account.update_attributes(msg_params) 
        flash[:notice] = "Successfully configured Communication Queues"
        format.html { redirect_to redirect_url }
        format.xml  { head :ok }
        format.js
      else
        @errors |= @provider_account.errors.full_messages unless @provider_account.errors.empty?
        flash[:error] = "Failed to configure Communication Queues:<br />"+@errors.join('<br />')+'<br />'+$!.to_s
        format.html { redirect_to redirect_url }
        format.xml  { render :xml => @provider_account.errors, :status => :unprocessable_entity }
        format.js
      end
    end
  end

  private
  
end
