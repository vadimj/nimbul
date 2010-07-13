class SnapshotsController < ApplicationController
    before_filter :login_required
    require_role  :admin, :unless => "current_user.has_snapshot_access?(Snapshot.find(params[:id]))"

    def update
        @snapshot = Snapshot.find(params[:id])
        
        respond_to do |format|
            if @snapshot.update_attributes(params[:snapshot])
                flash[:notice] = 'Snapshot was successfully updated.'
                format.html { redirect_to(@snapshot) }
                format.xml  { head :ok }
                format.js   { render :partial => 'snapshots/snapshot', :layout => false }
				format.json { render :json => @snapshot }
            else
                flash[:error] = 'There was a problem updating this Snapshot.'
                format.html { render :action => "edit" }
                format.xml  { render :xml => @snapshot.errors, :status => :unprocessable_entity }
                format.js   { render :partial => 'snapshots/snapshot', :layout => false }
				format.json { render :json => @snapshot }
            end
        end
    end
end
