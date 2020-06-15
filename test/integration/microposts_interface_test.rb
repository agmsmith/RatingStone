# frozen_string_literal: true

require 'test_helper'

class MicropostsInterfaceTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
  end

  test "micropost interface" do
    log_in_as(@user)
    get root_path
    assert_select 'div.pagination'
    assert_select 'input[type=file]' # Spot for uploading a picture.
    assert_select 'a[href=?]', '/?page=2' # Correct pagination link
    # Invalid submission
    assert_no_difference 'Micropost.count' do
      post microposts_path, params: { micropost: { content: "" } }
    end
    assert_select 'div#error_explanation'
    # Valid submission, no picture.
    content = "This micropost really ties the room together"
    assert_difference 'Micropost.count', 1 do
      post microposts_path, params: { micropost: { content: content } }
    end
    assert_redirected_to root_url
    follow_redirect!
    assert_match content, response.body
    # Delete post, should be a delete button on own posts.
    first_micropost = @user.microposts.first # Newest one is the first one.
    assert_select 'body div ol.microposts form.deletebutton[action=?]',
      micropost_path(first_micropost), count: 1
    assert_not first_micropost.images.attached?
    assert_difference 'Micropost.count', -1 do
      delete micropost_path(first_micropost)
    end
    # Valid submission with a picture.
    content = "This micropost has a picture too"
    image = fixture_file_upload('files/kitten.jpg', 'image/jpeg')
    assert_difference 'Micropost.count', 1 do
      post microposts_path, params: { micropost: {
        content: content, images: [image]
      } }
    end
    first_micropost = @user.microposts.first
    assert first_micropost.images.attached?
    assert_redirected_to root_url
    follow_redirect!
    assert_match content, response.body
    # Visit different user (no delete links)
    get user_path(users(:archer))
    assert_select 'body div ol.microposts form.deletebutton', count: 0
  end

  test "micropost sidebar count" do
    log_in_as(@user)
    get root_path
    assert_match "#{@user.microposts.count} microposts", response.body
    # User with zero microposts
    other_user = users(:malory)
    log_in_as(other_user)
    get root_path
    assert_match "0 microposts", response.body
    other_user.microposts.create!(content: "A micropost")
    get root_path
    assert_match "1 micropost", response.body
  end
end
