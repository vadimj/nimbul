require 'test_helper'

class InstanceKindCategoriesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:instance_kind_categories)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create instance_kind_category" do
    assert_difference('InstanceKindCategory.count') do
      post :create, :instance_kind_category => { }
    end

    assert_redirected_to instance_kind_category_path(assigns(:instance_kind_category))
  end

  test "should show instance_kind_category" do
    get :show, :id => instance_kind_categories(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => instance_kind_categories(:one).id
    assert_response :success
  end

  test "should update instance_kind_category" do
    put :update, :id => instance_kind_categories(:one).id, :instance_kind_category => { }
    assert_redirected_to instance_kind_category_path(assigns(:instance_kind_category))
  end

  test "should destroy instance_kind_category" do
    assert_difference('InstanceKindCategory.count', -1) do
      delete :destroy, :id => instance_kind_categories(:one).id
    end

    assert_redirected_to instance_kind_categories_path
  end
end
