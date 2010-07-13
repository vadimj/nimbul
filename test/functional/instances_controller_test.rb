require 'test_helper'

class InstancesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:instances)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create instance" do
    assert_difference('Instance.count') do
      post :create, :instance => { }
    end

    assert_redirected_to instance_path(assigns(:instance))
  end

  test "should show instance" do
    get :show, :id => instances(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => instances(:one).id
    assert_response :success
  end

  test "should update instance" do
    put :update, :id => instances(:one).id, :instance => { }
    assert_redirected_to instance_path(assigns(:instance))
  end

  test "should destroy instance" do
    assert_difference('Instance.count', -1) do
      delete :destroy, :id => instances(:one).id
    end

    assert_redirected_to instances_path
  end
end
