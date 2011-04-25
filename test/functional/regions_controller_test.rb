require 'test_helper'

class RegionsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:regions)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create region" do
    assert_difference('Region.count') do
      post :create, :region => { }
    end

    assert_redirected_to region_path(assigns(:region))
  end

  test "should show region" do
    get :show, :id => regions(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => regions(:one).id
    assert_response :success
  end

  test "should update region" do
    put :update, :id => regions(:one).id, :region => { }
    assert_redirected_to region_path(assigns(:region))
  end

  test "should destroy region" do
    assert_difference('Region.count', -1) do
      delete :destroy, :id => regions(:one).id
    end

    assert_redirected_to regions_path
  end
end
