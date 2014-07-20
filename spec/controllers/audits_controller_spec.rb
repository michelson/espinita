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
      
      # add current user accessor to controller
      AuditsController.send(:define_method, 'current_user=') {|user| self.instance_variable_set("@current_user", user)}
      AuditsController.send(:define_method, 'current_user') {self.instance_variable_get("@current_user")}

      controller.send(:current_user=, user)
      expect {
        post :audit
      }.to change( Espinita::Audit, :count )

      assigns(:general_model).audits.last.user.should == user
      assigns(:general_model).audits.last.remote_address.should == "0.0.0.0"

    end
    
    it "should audit without current_user defined" do
      expect {
        post :audit
      }.to change( Espinita::Audit, :count )

      assigns(:general_model).audits.last.user.should == nil
      assigns(:general_model).audits.last.remote_address.should == "0.0.0.0"

    end
  end

end
