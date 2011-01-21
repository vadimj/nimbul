require 'test_helper'

class InstanceKindsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:instance_kinds)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create instance_kind" do
    assert_difference('InstanceKind.count') do
      post :create, :instance_kind => { }
    end

    assert_redirected_to instance_kind_path(assigns(:instance_kind))
  end

  test "should show instance_kind" do
    get :show, :id => instance_kinds(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => instance_kinds(:one).id
    assert_response :success
  end

  test "should update instance_kind" do
    put :update, :id => instance_kinds(:one).id, :instance_kind => { }
    assert_redirected_to instance_kind_path(assigns(:instance_kind))
  end

  test "should destroy instance_kind" do
    assert_difference('InstanceKind.count', -1) do
      delete :destroy, :id => instance_kinds(:one).id
    end

    assert_redirected_to instance_kinds_path
  end
end
