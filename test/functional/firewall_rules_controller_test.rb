require 'test_helper'

class FirewallRulesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:firewall_rules)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create firewall_rule" do
    assert_difference('FirewallRule.count') do
      post :create, :firewall_rule => { }
    end

    assert_redirected_to firewall_rule_path(assigns(:firewall_rule))
  end

  test "should show firewall_rule" do
    get :show, :id => firewall_rules(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => firewall_rules(:one).id
    assert_response :success
  end

  test "should update firewall_rule" do
    put :update, :id => firewall_rules(:one).id, :firewall_rule => { }
    assert_redirected_to firewall_rule_path(assigns(:firewall_rule))
  end

  test "should destroy firewall_rule" do
    assert_difference('FirewallRule.count', -1) do
      delete :destroy, :id => firewall_rules(:one).id
    end

    assert_redirected_to firewall_rules_path
  end
end
