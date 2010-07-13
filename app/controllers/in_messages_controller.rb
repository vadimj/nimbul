class InMessagesController < ApplicationController
    # GET /in_messages
    # GET /in_messages.xml
    def index
        joins = nil
        conditions = nil
        params[:sort] = 'received_at_reverse' if params[:sort].blank?
        @messages = InMessage.search(params[:search], params[:page], joins, conditions, params[:sort])
        
        respond_to do |format|
            format.html
            format.xml  { render :xml => @messages }
            format.js   { render :partial => 'list', :layout => false }
        end
    end
    def list
        index
    end

  # GET /in_messages/1
  # GET /in_messages/1.xml
  def show
    @in_message = InMessage.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @in_message }
    end
  end

  # GET /in_messages/new
  # GET /in_messages/new.xml
  def new
    @in_message = InMessage.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @in_message }
    end
  end

  # GET /in_messages/1/edit
  def edit
    @in_message = InMessage.find(params[:id])
  end

  # POST /in_messages
  # POST /in_messages.xml
  def create
    @in_message = InMessage.new(params[:in_message])

    respond_to do |format|
      if @in_message.save
        flash[:notice] = 'InMessage was successfully created.'
        format.html { redirect_to(@in_message) }
        format.xml  { render :xml => @in_message, :status => :created, :location => @in_message }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @in_message.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /in_messages/1
  # PUT /in_messages/1.xml
  def update
    @in_message = InMessage.find(params[:id])

    respond_to do |format|
      if @in_message.update_attributes(params[:in_message])
        flash[:notice] = 'InMessage was successfully updated.'
        format.html { redirect_to(@in_message) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @in_message.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /in_messages/1
  # DELETE /in_messages/1.xml
  def destroy
    @in_message = InMessage.find(params[:id])
    @in_message.destroy

    respond_to do |format|
      format.html { redirect_to(in_messages_url) }
      format.xml  { head :ok }
    end
  end
end
