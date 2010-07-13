class KeyPairsController < ApplicationController
  before_filter :login_required, :except => [:index]
  require_role  :admin,
    :except => [:index],
    :unless => "params[:id].nil? or current_user.has_key_pair_access?(KeyPair.find(params[:id])) "

    def index
        @provider_account = ProviderAccount.find(params[:provider_account_id])
        @security_groups = @provider_account.security_groups

        if @provider_account.nil?
            redirect_to new_provider_account_path and return
        end

        # refresh this provider account if a refresh was requested
        # TODO - move to a separate action
        @provider_account.refresh(params[:refresh]) if params[:refresh]

		#
		# get corresponding key_pairs
		#
		joins = nil
		key_pair_conditions = [ 'provider_account_id = ?', @provider_account.id ]
        @key_pairs = KeyPair.search(params[:search], params[:page], joins, key_pair_conditions, params[:sort])

        respond_to do |format|
            format.html # index.html.erb
            format.xml  { render :xml => @key_pairs }
            format.js   { render :partial => 'key_pairs/list', :layout => false }
        end
	end
	def list
		index
	end

	# GET /key_pairs/1
	# GET /key_pairs/1.xml
	def show
		@key_pair = KeyPair.find(params[:id], :include => [ :key_pair_params, :security_groups ])
    	@key_pair_params = @key_pair.key_pair_params
		@security_groups = @key_pair.security_groups

		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @key_pair }
		end
	end

  # GET /key_pairs/new
  # GET /key_pairs/new.xml
  def new
    @key_pair = KeyPair.new
    @key_pair.key_pair_params.build( :name => 'ROLES' )

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @key_pair }
    end
  end

	# GET /key_pairs/1/edit
	def edit
		@key_pair = KeyPair.find(params[:id])
 
		respond_to do |format|
 			format.html # edit.html.erb
			format.json { render :json => @key_pair }
		end
	end

  # POST /key_pairs
  # POST /key_pairs.xml
  def create
    @cluster = Cluster.find(params[:cluster_id])
    @key_pair = @cluster.key_pairs.build(params[:key_pair])
    if @key_pair.save
      flash[:notice] = 'KeyPair was successfully created.'
	  respond_to do |format|
        format.html { redirect_to @cluster }
        format.js
      end
    else
      @failed = true
      respond_to do |format|
        format.html { redirect_to @cluster }
        format.js
      end
    end
  end

  def create_old
    @key_pair = KeyPair.new(params[:key_pair])

    respond_to do |format|
      if @key_pair.save
        flash[:notice] = 'KeyPair was successfully created.'
        format.html { redirect_to(@key_pair) }
        format.xml  { render :xml => @key_pair, :status => :created, :location => @key_pair }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @key_pair.errors, :status => :unprocessable_entity }
      end
    end
  end

    # PUT /key_pairs/1
    # PUT /key_pairs/1.xml
    # PUT /key_pairs/1.js
    def update
        @key_pair = KeyPair.find(params[:id])
        
        respond_to do |format|
            if @key_pair.update_attributes(params[:key_pair])
                flash[:notice] = 'Key Pair was successfully updated.'
                format.html { redirect_to(@key_pair) }
                format.xml  { head :ok }
                format.js   { render :partial => 'key_pairs/key_pair', :layout => false }
				format.json { render :json => @key_pair }
            else
                flash[:error] = 'There was a problem updating this Key Pair.'
                format.html { render :action => "edit" }
                format.xml  { render :xml => @key_pair.errors, :status => :unprocessable_entity }
                format.js   { render :partial => 'key_pairs/key_pair', :layout => false }
				format.json { render :json => @key_pair }
            end
        end
    end

  # DELETE /key_pairs/1
  # DELETE /key_pairs/1.xml
  def destroy
    @cluster = Cluster.find(params[:cluster_id])
    @key_pair = KeyPair.find(params[:id])
    @key_pair.destroy

    respond_to do |format|
      format.html { redirect_to @cluster }
      format.xml  { head :ok }
      format.js
    end
  end

end
