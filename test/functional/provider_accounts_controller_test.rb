require 'test_helper'

class ProviderAccountsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:provider_accounts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create provider_account" do
    assert_difference('ProviderAccount.count') do
      post :create, :provider_account => { }
    end

    assert_redirected_to provider_account_path(assigns(:provider_account))
  end

  test "should show provider_account" do
    get :show, :id => provider_accounts(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => provider_accounts(:one).id
    assert_response :success
  end

  test "should update provider_account" do
    put :update, :id => provider_accounts(:one).id, :provider_account => { }
    assert_redirected_to provider_account_path(assigns(:provider_account))
  end

  test "should destroy provider_account" do
    assert_difference('ProviderAccount.count', -1) do
      delete :destroy, :id => provider_accounts(:one).id
    end

    assert_redirected_to provider_accounts_path
  end
end
