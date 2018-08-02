class ApplicationController < ActionController::Base
    before_action :set_page
    def set_page
        id = params[:id]
        if id.nil?
          @link=''
        else
          @link_account="index?id=#{id}"
          @link_percent="new/percent?id=#{id}"
        end
  
      end
end
