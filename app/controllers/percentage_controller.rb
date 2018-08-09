class PercentageController < ApplicationController
    def show
        id = params[:id]
        @user=User.find_by_id(id)
        @percentages = @user.percentages
    end
end
