require 'test_helper'

class ProviderAccountParametersControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:provider_account_parameters)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create provider_account_parameter" do
    assert_difference('ProviderAccountParameter.count') do
      post :create, :provider_account_parameter => { }
    end

    assert_redirected_to provider_account_parameter_path(assigns(:provider_account_parameter))
  end

  test "should show provider_account_parameter" do
    get :show, :id => provider_account_parameters(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => provider_account_parameters(:one).id
    assert_response :success
  end

  test "should update provider_account_parameter" do
    put :update, :id => provider_account_parameters(:one).id, :provider_account_parameter => { }
    assert_redirected_to provider_account_parameter_path(assigns(:provider_account_parameter))
  end

  test "should destroy provider_account_parameter" do
    assert_difference('ProviderAccountParameter.count', -1) do
      delete :destroy, :id => provider_account_parameters(:one).id
    end

    assert_redirected_to provider_account_parameters_path
  end
end
