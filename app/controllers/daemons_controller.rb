class DaemonsController < ApplicationController
    before_filter :login_required
    require_role :admin
    
    def index
        @daemons = Daemon.find(:all)

        respond_to do |format|
            format.html
            format.xml  { render :xml => @daemons }
            format.js
        end
    end
    def list
        index
    end

    def control
        @daemons = (Daemon.find(params[:daemon_ids]) if params[:daemon_ids])
        @daemons.each do |daemon|
            unless params[:command].blank?
                if params[:command] == 'start'
                    if daemon.state == 'stopped'
                        daemon.start!
                        daemon.state = 'starting'
                    else
                        daemon.state = 'Daemon is already running'
                    end
                end
                if params[:command] == 'stop'
                    if daemon.state == 'running'
                        daemon.stop!
                        daemon.state = 'stopping'
                    else
                        daemon.state = 'Daemon is already stopped'
                    end
                end
                if params[:command] == 'restart'
                    if daemon.state == 'running'
                        daemon.restart!
                        daemon.state = 'restarting'
                    else
                        daemon.state = 'Daemon is stopped, start it first'
                    end
                end
            end
        end

        respond_to do |format|
            format.html { redirect_to :action => 'index' }
            format.xml  { head :ok }
            format.js
        end
    end

end
