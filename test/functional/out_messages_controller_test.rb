require 'test_helper'

class OutMessagesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:out_messages)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create out_message" do
    assert_difference('OutMessage.count') do
      post :create, :out_message => { }
    end

    assert_redirected_to out_message_path(assigns(:out_message))
  end

  test "should show out_message" do
    get :show, :id => out_messages(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => out_messages(:one).id
    assert_response :success
  end

  test "should update out_message" do
    put :update, :id => out_messages(:one).id, :out_message => { }
    assert_redirected_to out_message_path(assigns(:out_message))
  end

  test "should destroy out_message" do
    assert_difference('OutMessage.count', -1) do
      delete :destroy, :id => out_messages(:one).id
    end

    assert_redirected_to out_messages_path
  end
end
