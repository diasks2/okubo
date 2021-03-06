# -*- encoding: utf-8 -*-
require 'spec_helper'

describe Okubo::Item do
  before(:each) do
    @word = Word.create!(:kanji => "日本語", :kana => "にほんご", :translation => "Japanese language")
    @user = User.create!(:name => "Robert")
    @user.words << @word
  end

  context "Leitner box movement" do
    it "should present a list of all words" do
      @user.words.should == [@word]
      @user.words.count.should == 1
    end

    it "should start off in the untested stack" do
      @user.words.untested.should == [@word]
    end

    it "correct answer should move it up one stack" do
      @user.right_answer_for!(@word)
      @user.words.untested.should == []
      @user.words.box(1).should == [@word]
      @user.words.known.should == [@word]
    end

    it "incorrect answer should move it to the failed stack" do
      @user.wrong_answer_for!(@word)
      @user.words.untested.should == []
      @user.words.failed.should == [@word]
      @word.stats.times_wrong.should == 1
    end
  end

  context "Study schedule" do
    it "when untested, next study time should be nil" do
      @word.stats.next_review.should be_nil
    end

    it "when correct, next study time should gradually increase" do
      Timecop.freeze(Time.now) do
        @user.right_answer_for!(@word)
        stats = @word.stats
        stats.next_review.should == stats.last_reviewed + 3.days
        stats.times_right.should == 1
        @user.right_answer_for!(@word)
        stats.reload
        stats.next_review.should == stats.last_reviewed + 7.days
        stats.times_right.should == 2
        @user.right_answer_for!(@word)
        stats.reload
        stats.next_review.should == stats.last_reviewed + 14.days
        @user.right_answer_for!(@word)
        stats.reload
        stats.next_review.should == stats.last_reviewed + 30.days
        @user.right_answer_for!(@word)
        stats.reload
        stats.next_review.should == stats.last_reviewed + 60.days
        @user.right_answer_for!(@word)
        stats.reload
        stats.next_review.should == stats.last_reviewed + 120.days
        @user.right_answer_for!(@word)
        stats.reload
        stats.next_review.should == stats.last_reviewed + 240.days
      end
    end

    it "words should expire and move from known to expired" do
      @user.right_answer_for!(@word)
      @user.words.known.should == [@word]
      Timecop.travel(4.days)
      @user.words.known.should == []
      @user.words.expired.should == [@word]
      Timecop.return
    end
  end
end