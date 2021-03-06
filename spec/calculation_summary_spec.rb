# multi_column_calculation_summary_spec.rb

require 'spec_helper'

describe FinModeling::CalculationSummary do
  before(:all) do
    @summary = FinModeling::CalculationSummary.new
    @summary.title = "CS 1"
    @summary.rows = [ FinModeling::CalculationRow.new(:key => "Row", :vals => [nil, 0, nil, -101, 2.4]) ]
  end

  describe ".valid_vals" do # FIXME: ... this should be on the row, not on the summary ?
    subject { @summary.rows.first.valid_vals }
    it "should return all non-nil values" do
      subject.should == @summary.rows[0].vals.select{ |x| !x.nil? }
    end
  end

  describe ".filter_by_type" do
    before(:all) do
      @summary2 = FinModeling::CalculationSummary.new
      @summary2.rows = [ ]
      @summary2.rows << FinModeling::CalculationRow.new(:key => "Row", :type => :oa, :vals => [  4])
      @summary2.rows << FinModeling::CalculationRow.new(:key => "Row", :type => :fa, :vals => [109])
      @summary2.rows << FinModeling::CalculationRow.new(:key => "Row", :type => :oa, :vals => [ 93])
      @summary2.rows << FinModeling::CalculationRow.new(:key => "Row", :type => :fa, :vals => [  1])
    end
    subject { @summary2.filter_by_type(:oa) }
    it { should be_a FinModeling::CalculationSummary }
    it "should return a summary of only the requested type" do
      subject.rows.map{ |row| row.type }.uniq.should == [:oa]
    end
  end

  describe ".insert_column_before" do
    before(:each) do
      @summary2 = FinModeling::CalculationSummary.new
      @summary2.rows = [ ]
      @summary2.rows << FinModeling::CalculationRow.new(:key => "Row", :type => :oa, :vals => [  4])
      @summary2.rows << FinModeling::CalculationRow.new(:key => "Row", :type => :oa, :vals => [ 93])
    end
    context "when given a column index of 0 through (length-1)" do
      before(:each) do
        @summary2.insert_column_before(0)
      end
      subject { @summary2 }
      it "should insert a nil value in every row's vals, at the right column" do
        subject.rows.map{ |row| row.vals }.should == [ [ nil, 4], [ nil, 93 ] ]
      end
    end
    context "when given a column index greater than (length-1)" do
      before(:each) do
        @summary2.insert_column_before(2)
      end
      subject { @summary2 }
      it "should append columns as needed" do
        subject.rows.map{ |row| row.vals }.should == [ [ 4, nil, nil ], [ 93, nil, nil ] ]
      end
    end
  end

  describe ".auto_scale!" do
    before(:each) do
      @summary2 = FinModeling::CalculationSummary.new
    end
    context "when the minimum abs value is < 1M and >= 1k" do
      before(:each) do
        @summary2.rows = [ FinModeling::CalculationRow.new(:key => "Row", :type => :oa, :vals => [10000, -1000000, 20000]) ]
        @summary2.auto_scale!
      end
      subject { @summary2 }
      it "should scale all values down by 1k" do
        subject.rows.first.vals.should == [10.0, -1000.0, 20.0]
      end
      it "should append ' ($KK)' to all keys" do
        subject.rows.map{ |row| row.key }.all?{ |key| key =~ / \(\$KK\)$/ }.should be_true
      end
    end
    context "when the minimum abs value is >= 1M" do
      before(:each) do
        @summary2.rows = [ FinModeling::CalculationRow.new(:key => "Row", :type => :oa, :vals => [10000000, 1000000, -25000000]) ]
        @summary2.auto_scale!
      end
      subject { @summary2 }
      it "should scale all values down by 1k" do
        subject.rows.first.vals.should == [10.0, 1.0, -25.0]
      end
      it "should append ' ($MM)' to all keys" do
        subject.rows.map{ |row| row.key }.all?{ |key| key =~ / \(\$MM\)$/ }.should be_true
      end
    end
  end

  describe ".num_value_columns" do
    before(:all) do
      @summary2 = FinModeling::CalculationSummary.new
      @summary2.rows = [ ]
      @summary2.rows << FinModeling::CalculationRow.new(:key => "Row", :type => :oa, :vals => [])
      @summary2.rows << FinModeling::CalculationRow.new(:key => "Row", :type => :fa, :vals => [9])
      @summary2.rows << FinModeling::CalculationRow.new(:key => "Row", :type => :oa, :vals => [3,2,1])
      @summary2.rows << FinModeling::CalculationRow.new(:key => "Row", :type => :fa, :vals => [1])
    end
    subject { @summary2.num_value_columns }
    it "should return the width of the table (the maximum length of any row's vals)" do
      subject.should == @summary2.rows.map{ |row| row.vals.length }.max
    end
  end

  describe "+" do
    before(:all) do
      @mccs1 = FinModeling::CalculationSummary.new
      @mccs1.title = "MCCS 1"
      @mccs1.rows = [ FinModeling::CalculationRow.new(:key => "Row 1", :vals => [nil, 0, nil, -101, 2.4]) ]
    end

    context "when the two calculations have different keys (or the same keys in different orders)" do
      before(:all) do
        @mccs2 = FinModeling::CalculationSummary.new
        @mccs2.title = "MCCS 2"
        @mccs2.rows = [ FinModeling::CalculationRow.new(:key => "Row 1", :vals => [nil, 0, nil, -101, 2.4]) ]
      end
      subject { @mccs1 + @mccs2 }
  
      it { should be_a FinModeling::CalculationSummary }
      its(:title) { should == @mccs1.title }
      it "should set the row labels to the first summary's row labels" do
        subject.rows.map{ |row| row.key }.should == @mccs1.rows.map{ |row| row.key }
      end
      it "should merge the values of summary into an array of values in the result" do
        0.upto(subject.rows.length-1).each do |row_idx|
          subject.rows[row_idx].vals.should == ( @mccs1.rows[row_idx].vals + @mccs2.rows[row_idx].vals )
        end
      end
    end

    context "when the two calculations have different keys (or the same keys in different orders)" do
      before(:all) do
        @mccs3 = FinModeling::CalculationSummary.new
        @mccs3.title = "MCCS 3"
        @mccs3.rows =  [ FinModeling::CalculationRow.new(:key => "Row 2", :vals => [1, 0, nil, -101, 2.4]) ]
        @mccs3.rows += [ FinModeling::CalculationRow.new(:key => "Row 1", :vals => [32, 0, nil, nil, 2  ]) ]
      end
      subject { @mccs1 + @mccs3 }
      it "should have one row per unique key" do
        subject.rows.map{ |row| row.key }.sort.should == (@mccs1.rows + @mccs3.rows).map{ |row| row.key }.sort.uniq
      end
      it "should merge the values of summary into an array of values in the result" do
        expected_vals = []
        expected_vals << ([""]*@mccs1.num_value_columns + @mccs3.rows[0].vals)
        expected_vals << (@mccs1.rows[0].vals +           @mccs3.rows[1].vals)
        subject.rows.map{ |row| row.vals }.should == expected_vals
      end
    end
  end
end
