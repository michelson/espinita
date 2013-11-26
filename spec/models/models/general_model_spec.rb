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
      expect(general_model.permited_columns).to include("name")
      expect(general_model.permited_columns.size).to eql 1
    end

    it "general auditable except method" do
      general_model.auditable except: [:name]
      expect(general_model.excluded_cols).to include("name")
      expect(general_model.permited_columns).not_to include("name")
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

    it "model should be associated" do
      expect(updated_model.audits).to have(2).audits
    end
  end

  describe "update model with only name key" do

    let(:general_model) do
      FactoryGirl.create(:general_model)
    end

    let(:updated_model) do
      general_model.class.auditable except: [:name]
      general_model.update_attribute(:name , "Foo" )
      general_model
    end

    it "model should be associated" do
      expect(updated_model.audits).to have(1).audits
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

  describe 'create' do
    let(:general_model) { FactoryGirl.build :general_model }
    before { general_model.class.auditable }
    before { general_model.save }

    subject { Espinita::Audit.last }

    its(:action) { should eq 'create' }
  end

  describe 'update' do
    let(:general_model) { FactoryGirl.create :general_model }
    before { general_model.class.auditable }
    before { general_model.update_attributes name: 'Foo' }

    subject { Espinita::Audit.last }

    its(:action) { should eq 'update' }
  end

  describe 'destroy' do
    let(:general_model) { FactoryGirl.create :general_model }
    before { general_model.class.auditable }
    before { general_model.destroy }

    subject { Espinita::Audit.last }

    its(:action) { should eq 'destroy' }
  end
end
