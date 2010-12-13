require 'test_helper'

class InstanceTypeCategoriesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:instance_type_categories)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create instance_type_category" do
    assert_difference('InstanceTypeCategory.count') do
      post :create, :instance_type_category => { }
    end

    assert_redirected_to instance_type_category_path(assigns(:instance_type_category))
  end

  test "should show instance_type_category" do
    get :show, :id => instance_type_categories(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => instance_type_categories(:one).id
    assert_response :success
  end

  test "should update instance_type_category" do
    put :update, :id => instance_type_categories(:one).id, :instance_type_category => { }
    assert_redirected_to instance_type_category_path(assigns(:instance_type_category))
  end

  test "should destroy instance_type_category" do
    assert_difference('InstanceTypeCategory.count', -1) do
      delete :destroy, :id => instance_type_categories(:one).id
    end

    assert_redirected_to instance_type_categories_path
  end
end
