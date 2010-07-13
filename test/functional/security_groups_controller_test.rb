require 'test_helper'

class SecurityGroupsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:security_groups)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create security_group" do
    assert_difference('SecurityGroup.count') do
      post :create, :security_group => { }
    end

    assert_redirected_to security_group_path(assigns(:security_group))
  end

  test "should show security_group" do
    get :show, :id => security_groups(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => security_groups(:one).id
    assert_response :success
  end

  test "should update security_group" do
    put :update, :id => security_groups(:one).id, :security_group => { }
    assert_redirected_to security_group_path(assigns(:security_group))
  end

  test "should destroy security_group" do
    assert_difference('SecurityGroup.count', -1) do
      delete :destroy, :id => security_groups(:one).id
    end

    assert_redirected_to security_groups_path
  end
end
