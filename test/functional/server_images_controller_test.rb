require 'test_helper'

class ServerImagesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:server_images)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create server_image" do
    assert_difference('ServerImage.count') do
      post :create, :server_image => { }
    end

    assert_redirected_to server_image_path(assigns(:server_image))
  end

  test "should show server_image" do
    get :show, :id => server_images(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => server_images(:one).id
    assert_response :success
  end

  test "should update server_image" do
    put :update, :id => server_images(:one).id, :server_image => { }
    assert_redirected_to server_image_path(assigns(:server_image))
  end

  test "should destroy server_image" do
    assert_difference('ServerImage.count', -1) do
      delete :destroy, :id => server_images(:one).id
    end

    assert_redirected_to server_images_path
  end
end
