class CampaignsController < ApplicationController
  def show
    @campaign = Campaign.find(params[:id])
  end

  def new
    @campaign = Campaign.new(:campaign_type => params[:campaign_type].to_sym)
  end

  def create
    @campaign = Campaign.new(params[:campaign].merge(:owner => current_user, :end_date => Date.today + 30.days))
    convertFromDollarsToCents
    if user_signed_in?
      store_temp_campaign_data
      do_create
    else
      store_temp_campaign_data
      authenticate_user!
    end
  end

  def do_create
    @campaign ||= session[:campaign]
    @campaign.save!
    redirect_to campaign_path(@campaign)
  end

  def donate
    @campaign = Campaign.find(params[:campaign_id])
    cancel_url = campaign_url(@campaign.id)
    return_url = campaign_return_from_paypal_url(@campaign.id)
    redirect_to DonationService.new.setup_donation(@campaign,
        params[:amount].to_i * 100,
        params[:first_name],
        params[:last_name],
        cancel_url,
        return_url,
        request.remote_ip)
  end

  def return_from_paypal
    donation = DonationService.new.complete_donation(params[:token],
      params[:PayerID],
      params[:order_id])

    redirect_to campaign_path(donation.campaign.id)
  end

  private

  def store_temp_campaign_data
    session[:campaign] = @campaign
    session[:return_url] = do_create_campaigns_url
  end

  def convertFromDollarsToCents 
    @campaign.goal_in_cents =  params[:campaign][:goal_in_cents].to_f * 100
  end
end
