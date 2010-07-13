class Admin::ControlsController < ApplicationController
    before_filter :login_required
    require_role :admin

    def index
        @users = User.count
        @service_types = ServiceType.count
        @service_providers = ServiceProvider.count
        @service_overrides = ServiceOverride.count
        @daemons = Daemon.count
        @exceptions = LoggedException.count
        @in_messages = InMessage.count
        @out_messages = OutMessage.count
    end
end
