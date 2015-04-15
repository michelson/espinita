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

  describe "history_from_audits_for" do
    before do
      Timecop.freeze(Time.now.localtime)
    end

    after do
      Timecop.return
    end

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
          {name:"Foo", changed_at: Time.now.localtime.strftime('%Y-%m-%dT%l:%M:%S%z')}
        ])
      end

      it "should accept a string column name" do
        expect(updated_model.history_from_audits_for("name")).to eq([
          {name:"Foo", changed_at: Time.now.localtime.strftime('%Y-%m-%dT%l:%M:%S%z')}
        ])
      end

      it "should handle multiple audits" do
        later = Time.now.localtime + 10.days
        even_later = Time.now.localtime + 1.year

        Timecop.freeze(later) do
          updated_model.update_attributes(name: "Baz", audit_comment: "Some comment" )
        end
        Timecop.freeze(even_later) do
          updated_model.update_attributes(name: "Arglebargle", audit_comment: "Some comment" )
        end
        expect(updated_model.history_from_audits_for(:name)).to eq(
          [
            {name:"Arglebargle", changed_at: even_later.strftime('%Y-%m-%dT%l:%M:%S%z')},
            {name:"Baz", changed_at: later.strftime('%Y-%m-%dT%l:%M:%S%z')},
            {name:"Foo", changed_at: Time.now.localtime.strftime('%Y-%m-%dT%l:%M:%S%z')},
          ]
        )
      end
    end

    context "for multiple specified columns" do
      let!(:later){ Time.now.localtime + 10.days }
      let!(:even_later){ Time.now.localtime + 1.year }

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
            {name: "Arglebargle", settings: "Waffles", changed_at: even_later.strftime('%Y-%m-%dT%l:%M:%S%z')},
            {name: "Baz", changed_at: later.strftime('%Y-%m-%dT%l:%M:%S%z')},
            {name: "Foo", changed_at: Time.now.localtime.strftime('%Y-%m-%dT%l:%M:%S%z')},
          ]
        )
        expect(updated_model.history_from_audits_for([:position, :settings])).to eq(
          [
            {settings: "Waffles", changed_at: even_later.strftime('%Y-%m-%dT%l:%M:%S%z')},
            {position: 42, changed_at: later.strftime('%Y-%m-%dT%l:%M:%S%z')},
          ]
        )
      end

    end

    it "should raise an error if the requested column does not exist" do
      expect{ updated_model.history_from_audits_for(:waffles) }.to raise_error(ArgumentError)
    end

  end

  describe "restore" do

    context "given valid arguments" do

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
        Timecop.freeze(recent) do
          general_model.update_attributes(name: "Baz", settings: "Waffles", position: nil, audit_comment: "Some comment" )
        end
        Timecop.freeze(less_recent) do
          general_model.update_attributes(name: "Arglebargle", settings: "IHOP", audit_comment: "Some comment" )
        end
        Timecop.freeze(ancient) do
          general_model.update_attributes(name: "Walrus", audit_comment: "Some comment" )
        end
        general_model
      end


      it "should restore a single property from a datetime" do
        historical_model.restore_attributes(:name, DateTime.now - 12.days)
        expect(historical_model.name).to eq("Arglebargle")
      end

      it "should restore multiple attributes from a datetime" do
        historical_model.restore_attributes(:name, DateTime.now - 12.days)
        expect(historical_model.name).to eq("Arglebargle")
        expect(historical_model.settings).to eq("IHOP")
      end

      xit "should restore a single property that has been emptied when no datetime is specified" do
        historical_model.restore_attributes(:name)
        expect(historical_model.position).to eq(1)
      end

      xit "should restore a multiple attributes that have been emptied when no datetime is specified" do
        historical_model.restore_attributes(:name, DateTime.now - 12.days)
        expect(historical_model.position).to eq(1)
      end

    end

    context "given invalid arguments" do
      let!(:general_model) do
        [:create, :update, :destroy].each do |c|
           GeneralModel.reset_callbacks(c)
         end
        GeneralModel.auditable on: [:update]
        FactoryGirl.create(:general_model)
      end

      let!(:historical_model) do
        general_model.update_attributes(name: "Foo", audit_comment: "Some comment" )
        general_model
      end

      xit "given a single property that has not been emptied and no datetime" do
        historical_model.restore_attributes(:name, DateTime.now - 10.days)
      end
      xit "should raise when called with no arguments" do
        expect{ historical_model.restore_attributes }.to raise_error(ArgumentError)
      end

    end

  end

end
