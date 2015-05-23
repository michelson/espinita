require 'spec_helper'


describe GeneralModel do
  it{should have_many :audits}

  let(:current_user) do
    FactoryGirl.create(:user)
  end

  describe "model" do

    let(:general_model) do
      GeneralModel
    end

    it "general model checks" do
      expect(subject.audits).to be_empty
    end

    it "general auditable only method" do
      general_model.auditable only: [:name]
      expect(general_model.permitted_columns).to include("name")
      expect(general_model.permitted_columns.size).to eql 1
    end

    it "general auditable except method" do
      general_model.auditable except: [:name]
      expect(general_model.excluded_cols).to include("name")
      expect(general_model.permitted_columns).not_to include("name")
    end
  end

  describe "update model with only name key" do

    let(:general_model) do
      FactoryGirl.create(:general_model)
    end

    let(:updated_model) do
      general_model.class.auditable only: [:name]
      general_model.update_attribute(:name , "Foo" )
      general_model
    end

    let(:excluded_cols){
      updated_model.class.excluded_cols & updated_model.audits.last.audited_changes.keys.map(&:to_s)
    }

    it "auditable should not save exluded cols in changes" do
      expect(excluded_cols).to be_empty
    end

    it "model should be associated" do
      expect(updated_model.audits).to have(2).audits
    end
  end

  describe "update model with exclusion key" do

    let(:general_model) do
      FactoryGirl.create(:general_model)
    end

    let(:updated_model) do
      general_model.class.auditable except: [:name]
      general_model.update_attribute(:name , "Foo" )
      general_model
    end

    let(:excluded_cols){
      updated_model.class.excluded_cols & updated_model.audits.last.audited_changes.keys.map(&:to_s)
    }

    it "auditable should not save exluded cols in changes" do

      expect(excluded_cols).to_not be_empty
    end

    it "model should be associated and not include name in audited_changes" do
      expect(updated_model.audits).to have(1).audits
      expect(updated_model.audits.first.audited_changes.keys).to_not include("name")
    end

    it "model should have an array of 2 values on audited changes " do
      updated_model.audits.last.audited_changes.keys.each do |key|
        expect(updated_model.audits.last.audited_changes[key.to_sym].size).to eql(2)
      end
    end
  end

  describe "update with audit comment" do

    let(:general_model) do
      FactoryGirl.create(:general_model)
    end

    let(:updated_model) do
      general_model.class.auditable
      general_model.update_attributes(name: "Foo", audit_comment: "Some comment" )
      general_model
    end

    it "auditable should be created with comment" do
      expect(updated_model).to have(2).audits
      expect(updated_model.audits.last.comment).to_not be_empty
      expect(updated_model.audits.last.comment).to_not be "Some comment"
    end

    it "auditable should be created with comment" do
      expect(updated_model).to have(2).audits
      expect(updated_model.audits.last.version).to_not be_blank
      expect(updated_model.audits.last.version).to eql 2
    end
  end

  describe "save with current user" do

    before :each do
      RequestStore.store[:audited_user] = current_user
    end

    let(:general_model) do
      FactoryGirl.create(:general_model)
    end

    let(:updated_model) do
      general_model.class.auditable
      general_model.update_attributes(name: "Foo", audit_comment: "Some comment" )
      general_model
    end

    it "auditable should set current user" do
      expect(updated_model.audits.last.user).to_not be_blank
      expect(updated_model.audits.last.user).to be_an_instance_of User
      expect(updated_model.audits.last.user).to eql current_user
    end
  end

  describe "audit defaults excepts" do
    let(:general_model) do
      [:create, :update, :destroy].each do |c|
         GeneralModel.reset_callbacks(c)
       end
      GeneralModel.auditable on: [:update]
      FactoryGirl.create(:general_model)
    end

    let(:updated_model) do
      general_model.update_attributes(updated_at: 1.day.from_now )
      general_model
    end

    it "should have 1 audit" do
      expect(updated_model).to have(0).audits
    end
  end

  describe "audit only on create" do

    let(:general_model) do
      [:create, :update, :destroy].each do |c|
         GeneralModel.reset_callbacks(c)
       end
      GeneralModel.auditable on: [:create]
      FactoryGirl.create(:general_model)
    end

    let(:updated_model) do
      general_model.update_attributes(name: "Foo", audit_comment: "Some comment" )
      general_model
    end

    it "should have 1 audit" do
      expect(updated_model).to have(1).audits
      expect(updated_model.audits.last.version).to_not be_blank
      expect(updated_model.audits.last.version).to eql 1
    end
  end

  describe "audit only on update" do

    let(:general_model) do
      [:create, :update, :destroy].each do |c|
         GeneralModel.reset_callbacks(c)
       end
      GeneralModel.auditable on: [:update]
      FactoryGirl.create(:general_model)
    end

    let(:updated_model) do
      general_model.update_attributes(name: "Foo", audit_comment: "Some comment" )
      general_model
    end

    it "should have 1 audit" do
      expect(updated_model).to have(1).audits
      expect(updated_model.audits.last.version).to_not be_blank
      expect(updated_model.audits.last.version).to eql 1
    end
  end

  describe "audit when delete model" do
    let(:model) do
      [:create, :update, :destroy].each do |c|
         GeneralModel.reset_callbacks(c)
       end
      GeneralModel.auditable on: [:destroy]
      FactoryGirl.create(:general_model)
    end

    it "should create 1 audit when destroy" do
      expect(model).to have(0).audits
      model.destroy
      expect(model).to have(1).audits
      expect(model.audits.last.comment).to include("deleted model #{model.id}")
    end
  end

  context "history_from_audits_for" do
    before do
      Timecop.freeze(Time.now.localtime)
    end

    after do
      Timecop.return
    end

    let!(:later){ Time.now.localtime + 10.days }
    let!(:even_later){ Time.now.localtime + 1.year }

    let!(:general_model) do
      [:create, :update, :destroy].each do |c|
         GeneralModel.reset_callbacks(c)
       end
      GeneralModel.auditable on: [:update]
      FactoryGirl.create(:general_model)
    end

    let!(:updated_model) do
      general_model.update_attributes(name: "Foo", audit_comment: "Some comment" )
      general_model
    end

    context "given a single column as an argument" do

      it "should accept a symbol column name" do
        expect(updated_model.history_from_audits_for(:name)).to eq([
          {changes: {name:"Foo"}, changed_at: Time.now.localtime}
        ])
      end

      it "should accept a string column name" do
        expect(updated_model.history_from_audits_for("name")).to eq([
          {changes: {name:"Foo"}, changed_at: Time.now.localtime}
        ])
      end

      it "should handle multiple audits" do
        Timecop.freeze(later) do
          updated_model.update_attributes(name: "Baz", audit_comment: "Some comment" )
        end
        Timecop.freeze(even_later) do
          updated_model.update_attributes(name: "Arglebargle", audit_comment: "Some comment" )
        end
        expect(updated_model.history_from_audits_for(:name)).to eq(
          [
            {changes: {name:"Arglebargle"}, changed_at: even_later},
            {changes: {name:"Baz"}, changed_at: later},
            {changes: {name:"Foo"}, changed_at: Time.now.localtime},
          ]
        )
      end
    end

    context "for multiple specified columns" do

      before do
        Timecop.freeze(later) do
          updated_model.update_attributes(name: "Baz", position: 42, audit_comment: "Some comment" )
        end
        Timecop.freeze(even_later) do
          updated_model.update_attributes(name: "Arglebargle", settings: "Waffles", audit_comment: "Some comment" )
        end
      end

      it "should return history including each specified column" do
        expect(updated_model.history_from_audits_for([:name, :settings])).to eq(
          [
            {changes: {name: "Arglebargle", settings: "Waffles"}, changed_at: even_later},
            {changes: {name: "Baz"}, changed_at: later},
            {changes: {name: "Foo"}, changed_at: Time.now.localtime},
          ]
        )
        expect(updated_model.history_from_audits_for([:position, :settings])).to eq(
          [
            {changes: {settings: "Waffles"}, changed_at: even_later},
            {changes: {position: 42}, changed_at: later},
          ]
        )
      end

    end

    it "should raise an error if the requested column does not exist" do
      expect{ updated_model.history_from_audits_for(:waffles) }.to raise_error(ArgumentError)
    end

  end

  context "restore_attributes!" do

    let!(:general_model) do
      [:create, :update, :destroy].each do |c|
        GeneralModel.reset_callbacks(c)
      end
      GeneralModel.auditable on: [:update]
      FactoryGirl.create(:general_model)
    end

    let!(:historical_model) do
      recent = Time.now.localtime - 10.days
      less_recent = Time.now.localtime - 50.days
      ancient = Time.now.localtime - 1.year
      # these timed changes must be made in reverse chrono order to make the audits work for testing
      Timecop.freeze(ancient) do
        general_model.update_attributes(name: "Walrus", position: 1, audit_comment: "Some comment" )
      end
      Timecop.freeze(less_recent) do
        general_model.update_attributes(name: "Arglebargle", settings: "IHOP", position: 2, audit_comment: "Some comment" )
      end
      Timecop.freeze(recent) do
        general_model.update_attributes(name: "Baz", settings: "", position: nil, audit_comment: "Some comment" )
      end
      general_model
    end

    context "given valid arguments" do

      it "should restore a single property from a datetime" do
        result = historical_model.restore_attributes!(:name, DateTime.now - 12.days)

        expect(result).to be(true)
        expect(historical_model.name).to eq("Arglebargle")
      end

      it "should restore multiple attributes from a datetime" do
        result = historical_model.restore_attributes!([:name, :settings], DateTime.now - 57.days)

        expect(result).to be(true)
        expect(historical_model.name).to eq("Walrus")
        expect(historical_model.settings).to eq("MyText")
      end

      it "should return false when no restoration change is performed" do
        original = historical_model
        result = historical_model.restore_attributes!(:settings, DateTime.now + 5.days)

        expect(original).to match(historical_model)
        expect(result).to be(false)
      end

    end

    context "given invalid arguments" do

      it "should raise when called with no arguments" do
        expect{ historical_model.restore_attributes! }.to raise_error(ArgumentError)
      end

    end

  end

  context "restore_to_audit" do

    let!(:general_model) do
      [:create, :update, :destroy].each do |c|
        GeneralModel.reset_callbacks(c)
      end
      GeneralModel.auditable on: [:update]
      FactoryGirl.create(:general_model)
    end

    context "given valid arguments" do
      it "should restore when given an audit id" do
        original_model = general_model.dup

        general_model.update_attributes(name: "Ringo", settings: "Walrus")
        general_model.update_attributes(settings: "Walrus", position: 7)
        general_model.update_attributes(name: "Ringo", position: 3)
        general_model.restore_to_audit(general_model.audits.first.id)

        expect(general_model.name).to eq(original_model.name)
        expect(general_model.settings).to eq(original_model.settings)
      end

      it "should restore when given an audit record" do
        original_model = general_model.dup

        general_model.update_attributes(name: "Ringo", settings: "Walrus")
        general_model.update_attributes(settings: "Walrus", position: 7)
        general_model.update_attributes(name: "Ringo", position: 3)
        general_model.restore_to_audit(general_model.audits.first.id)

        expect(general_model.name).to eq(original_model.name)
        expect(general_model.settings).to eq(original_model.settings)
      end
    end

    context "given invalid arguments" do

      let!(:other_model) do
        other_model = general_model.dup
        other_model.save
        other_model.update_attributes(name: "Foo", settings: "Bar")
        other_model
      end

      it "should raise when called with a valid audit id for a different model" do
        expect{ general_model.restore_to_audit(other_model.audits.first.id) }.to raise_error
      end

      it "should raise when called with a valid audit record for a different model" do
        expect{ general_model.restore_to_audit(other_model.audits.first) }.to raise_error
      end

      it "should raise when called with an invalid audit id" do
        expect{ general_model.restore_to_audit(999999999) }.to raise_error
      end

    end

  end

end
