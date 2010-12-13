require 'test_helper'

class OperatingSystemsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:operating_systems)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create operating_system" do
    assert_difference('OperatingSystem.count') do
      post :create, :operating_system => { }
    end

    assert_redirected_to operating_system_path(assigns(:operating_system))
  end

  test "should show operating_system" do
    get :show, :id => operating_systems(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => operating_systems(:one).id
    assert_response :success
  end

  test "should update operating_system" do
    put :update, :id => operating_systems(:one).id, :operating_system => { }
    assert_redirected_to operating_system_path(assigns(:operating_system))
  end

  test "should destroy operating_system" do
    assert_difference('OperatingSystem.count', -1) do
      delete :destroy, :id => operating_systems(:one).id
    end

    assert_redirected_to operating_systems_path
  end
end
