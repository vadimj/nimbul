require File.dirname(__FILE__) + '/../spec_helper'
 
describe ServiceProvidersController do
  fixtures :all
  integrate_views
  
  it "index action should render index template" do
    get :index
    response.should render_template(:index)
  end
  
  it "show action should render show template" do
    get :show, :id => ServiceProvider.first
    response.should render_template(:show)
  end
  
  it "new action should render new template" do
    get :new
    response.should render_template(:new)
  end
  
  it "create action should render new template when model is invalid" do
    ServiceProvider.any_instance.stubs(:valid?).returns(false)
    post :create
    response.should render_template(:new)
  end
  
  it "create action should redirect when model is valid" do
    ServiceProvider.any_instance.stubs(:valid?).returns(true)
    post :create
    response.should redirect_to(service_provider_url(assigns[:service_provider]))
  end
  
  it "edit action should render edit template" do
    get :edit, :id => ServiceProvider.first
    response.should render_template(:edit)
  end
  
  it "update action should render edit template when model is invalid" do
    ServiceProvider.any_instance.stubs(:valid?).returns(false)
    put :update, :id => ServiceProvider.first
    response.should render_template(:edit)
  end
  
  it "update action should redirect when model is valid" do
    ServiceProvider.any_instance.stubs(:valid?).returns(true)
    put :update, :id => ServiceProvider.first
    response.should redirect_to(service_provider_url(assigns[:service_provider]))
  end
  
  it "destroy action should destroy model and redirect to index action" do
    service_provider = ServiceProvider.first
    delete :destroy, :id => service_provider
    response.should redirect_to(service_providers_url)
    ServiceProvider.exists?(service_provider.id).should be_false
  end
end
