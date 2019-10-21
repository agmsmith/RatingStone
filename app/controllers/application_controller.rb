# frozen_string_literal: true

class ApplicationController < ActionController::Base
  def hello
    render html: "Hello, world!"
  end
end
