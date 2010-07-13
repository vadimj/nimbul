require 'test_helper'

class InMessagesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:in_messages)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create in_message" do
    assert_difference('InMessage.count') do
      post :create, :in_message => { }
    end

    assert_redirected_to in_message_path(assigns(:in_message))
  end

  test "should show in_message" do
    get :show, :id => in_messages(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => in_messages(:one).id
    assert_response :success
  end

  test "should update in_message" do
    put :update, :id => in_messages(:one).id, :in_message => { }
    assert_redirected_to in_message_path(assigns(:in_message))
  end

  test "should destroy in_message" do
    assert_difference('InMessage.count', -1) do
      delete :destroy, :id => in_messages(:one).id
    end

    assert_redirected_to in_messages_path
  end
end
