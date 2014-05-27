require 'spec_helper'

describe "advertising_campaigns/show.html.haml" do
  before(:each) do
    @advertising_campaign = assign(:advertising_campaign, stub_model(AdvertisingCampaign,
      :partner_id => 1,
      :reference_code => "Reference Code"
    ))
    partner = FactoryGirl.create(:partner)
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Reference Code/)
  end
end
