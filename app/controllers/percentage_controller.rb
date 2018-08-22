class PercentageController < ApplicationController
    def show
        id = params[:id]
        @user=User.find_by_id(id)
        @percentages = @user.percentages
        @respond_times = @percentages.inject(0){|sum,x| sum + x.reply_time }
        @all_comments = @percentages.inject(0){|sum,x| sum + x.total_cm }
        #pespond percentage
        case @user.repond_percentage
        when 0..0.05
            @percentage_level = "C-"
        when 0.05..0.1
            @percentage_level = "C0"
        when 0.1..0.15
            @percentage_level = "C+"
        when 0.15..0.2
            @percentage_level = "B-"
        when 0.2..0.25
            @percentage_level = "B0"
        when 0.25..0.3
            @percentage_level = "B+"
        when 0.3..0.3333
            @percentage_level = "A-"
        when 0.3333..0.4
            @percentage_level = "A0"
        else
            @percentage_level = "A+"
        end
    end
end
