require 'test_helper'

class ServersControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:servers)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create server" do
    assert_difference('Server.count') do
      post :create, :server => { }
    end

    assert_redirected_to server_path(assigns(:server))
  end

  test "should show server" do
    get :show, :id => servers(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => servers(:one).id
    assert_response :success
  end

  test "should update server" do
    put :update, :id => servers(:one).id, :server => { }
    assert_redirected_to server_path(assigns(:server))
  end

  test "should destroy server" do
    assert_difference('Server.count', -1) do
      delete :destroy, :id => servers(:one).id
    end

    assert_redirected_to servers_path
  end

  test "should create server and redirect to cluster without javascript" do
    c = Cluster.create!(:name => 'hello')
    post :create, :cluster_id => c.id, :server => { :name => 'test server' }
    assert_redirected_to cluster_url(c)
    assert_equal 'test server', c.servers.first.name
  end

  test "should create comment and render RJS template for ajax" do
    c = Cluster.create!(:name => 'hello')
    post :create, :format => js, :cluster_id => c.id, :server => { :name => 'test server' }
    assert_template 'create.js.rjs'
    assert_equal 'test server', c.servers.first.name
  end
    
end
