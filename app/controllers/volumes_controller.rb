class VolumesController < ApplicationController
	before_filter :login_required
	require_role  :admin, :unless => "current_user.has_volume_access?(Volume.find(params[:id])) "

    def update
        @volume = Volume.find(params[:id])
        
        respond_to do |format|
            if @volume.update_attributes(params[:volume])
                flash[:notice] = 'Volume was successfully updated.'
                format.html { redirect_to(@volume) }
                format.xml  { head :ok }
                format.js   { render :partial => 'volumes/volume', :layout => false }
				format.json { render :json => @volume }
            else
                flash[:error] = 'There was a problem updating this volume.'
                format.html { render :action => "edit" }
                format.xml  { render :xml => @volume.errors, :status => :unprocessable_entity }
                format.js   { render :partial => 'volumes/volume', :layout => false }
				format.json { render :json => @volume }
            end
        end
    end
end
