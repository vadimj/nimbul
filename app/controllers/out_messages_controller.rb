class OutMessagesController < ApplicationController
    # GET /out_messages
    # GET /out_messages.xml
    def index
        joins = nil
        conditions = nil
        params[:sort] = 'sent_at_reverse' if params[:sort].blank?
        @messages = OutMessage.search(params[:search], params[:page], joins, conditions, params[:sort])

        respond_to do |format|
            format.html # index.html.erb
            format.xml  { render :xml => @messages }
            format.js   { render :partial => 'list', :layout => false }
        end
    end
    def list
        index
    end

  # GET /out_messages/1
  # GET /out_messages/1.xml
  def show
    @out_message = OutMessage.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @out_message }
    end
  end

  # GET /out_messages/new
  # GET /out_messages/new.xml
  def new
    @out_message = OutMessage.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @out_message }
    end
  end

  # GET /out_messages/1/edit
  def edit
    @out_message = OutMessage.find(params[:id])
  end

  # POST /out_messages
  # POST /out_messages.xml
  def create
    @out_message = OutMessage.new(params[:out_message])

    respond_to do |format|
      if @out_message.save
        flash[:notice] = 'OutMessage was successfully created.'
        format.html { redirect_to(@out_message) }
        format.xml  { render :xml => @out_message, :status => :created, :location => @out_message }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @out_message.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /out_messages/1
  # PUT /out_messages/1.xml
  def update
    @out_message = OutMessage.find(params[:id])

    respond_to do |format|
      if @out_message.update_attributes(params[:out_message])
        flash[:notice] = 'OutMessage was successfully updated.'
        format.html { redirect_to(@out_message) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @out_message.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /out_messages/1
  # DELETE /out_messages/1.xml
  def destroy
    @out_message = OutMessage.find(params[:id])
    @out_message.destroy

    respond_to do |format|
      format.html { redirect_to(out_messages_url) }
      format.xml  { head :ok }
    end
  end
end
