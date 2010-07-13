class ProviderAccount::ClustersController < ApplicationController
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_provider_account_access?(ProviderAccount.find(params[:provider_account_id])) "
end
