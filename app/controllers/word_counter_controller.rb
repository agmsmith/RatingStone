# frozen_string_literal: true

class WordCounterController < ApplicationController
  def update
    @vo_script = params[:vo_script]
    @vo_script = "Replace this text with your script..." unless @vo_script
    words = @vo_script.downcase.split(/\s+/).sort
    @word_count = words.length
    @word_list = Hash.new(0)
    words.each do |word|
      @word_list[word] += 1
    end
    @vo_expanded = "Not done yet; expanded version of script ->>#{@vo_script}<<- with all the words expanded to longer words will go here."
    render
  end
end
