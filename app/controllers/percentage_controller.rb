class PercentageController < ApplicationController
    def show
        id = params[:id]
        @user=User.find_by_id(id)
        @percentages = @user.percentages
        @respond_times = @percentages.inject(0){|sum,x| sum + x.reply_time }
        @all_comments = @percentages.inject(0){|sum,x| sum + x.total_cm }
    end
end
