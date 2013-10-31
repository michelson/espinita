require 'spec_helper'

class AuditsController < ActionController::Base
  def audit
    @general_model = FactoryGirl.create(:general_model)
    render :nothing => true
  end

  def update_user
    current_user.update_attributes( :password => 'foo')
    render :nothing => true
  end

  private

  attr_accessor :current_user
  attr_accessor :custom_user
end


describe AuditsController do

  before :each do 
    GeneralModel.auditable
  end

  let( :general_model ){
    FactoryFirl.create(:general_model)
  }

  let( :user ) { FactoryGirl.create(:user) }

  describe "POST audit" do

    it "should audit user" do
      controller.send(:current_user=, user)
      expect {
        post :audit
      }.to change( Espinita::Audit, :count )

      assigns(:general_model).audits.last.user.should == user
      assigns(:general_model).audits.last.remote_address.should == "0.0.0.0"

    end
  end

end
