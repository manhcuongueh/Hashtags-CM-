class ApplicationController < ActionController::Base
    before_action :set_page
    def set_page
        id = params[:id]
        if id.nil?
        else
          @link_account="index?id=#{id}"
        end
  
      end
end
