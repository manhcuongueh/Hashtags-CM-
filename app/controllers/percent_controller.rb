class PercentController < ApplicationController
    def new_percent
        @id=params[:id]
    end
    def change_percent
        @percentage=params[:percent]
        @id=params[:id]
        @user = User.find_by_id(@id)
        @hashtags=@user.hashtags
        @user.sum=0
        for i in @hashtags
            if i.use_by_global > (@percentage.to_f/100)*@user.followers
                i.avai ="X"
            else
                i.avai ="0"
            end
            #get sum 
            if i.avai =="0" && @hashtags.index(i) < 5
                @user.sum = @user.sum + (i.use_by_user) * (i.use_by_global)
            end
        end
        @user.score = @user.sum.to_f/@user.followers
            #get level
            case @user.score
            when 0..0.02
                @user.level = "C-"
            when 0.02..0.06
                @user.level = "C"
            when 0.06..0.1
                @user.level = "C+"
            when 0.1..0.25
                @user.level = "B-"
            when 0.25..0.5
                @user.level = "B"
            when 0.5..1
                @user.level = "B+"
            when 1..2
                @user.level = "A-"
            when 2..5
                @user.level = "A"
            else
                @user.level = "A+"
            end
            return @user
    end
    def write_excel
        #get param
        @user = change_percent
        @hashtags= @user.hashtags
        #generate new Excel file
        workbook = RubyXL::Workbook.new
        worksheet=workbook[0]
        #save information for all post
        worksheet.add_cell(0, 1, "PERCENTAGE")
        worksheet.add_cell(0, 2, "ID")
        worksheet.add_cell(0, 3, "FOLLOWERS")
        worksheet.add_cell(0, 4, "LEVEL")
        worksheet.add_cell(0, 5, "SCORE")
        worksheet.add_cell(0, 6, "SUM")
        worksheet.add_cell(1, 1, @percentage)
        worksheet.add_cell(1, 2, @user.username)
        worksheet.add_cell(1, 3, @user.followers)
        worksheet.add_cell(1, 4, @user.level)
        worksheet.add_cell(1, 5, @user.score)
        worksheet.add_cell(1, 6, @user.sum)
        #write hashtags
        worksheet.add_cell(3, 0, "RANK")
        worksheet.add_cell(3, 1, "HASHTAG")
        worksheet.add_cell(3, 2, "TIMES")
        worksheet.add_cell(3, 3, "GLOBAL TIMES")
        worksheet.add_cell(3, 4, "VALUE")
        worksheet.add_cell(3, 5, "AVAILABILITY")
        i=0
        for hashtag in @hashtags
             worksheet.add_cell(i+4, 0, i+1)
             worksheet.add_cell(i+4, 1, hashtag.hashtags)
             worksheet.add_cell(i+4, 2, hashtag.use_by_user)
             worksheet.add_cell(i+4, 3, hashtag.use_by_global)
             worksheet.add_cell(i+4, 4, hashtag.avai == "0" ? hashtag.use_by_global*hashtag.use_by_user : 0 )
             worksheet.add_cell(i+4, 5, hashtag.avai)  
             i=i+1   
        end
            #send
            send_data( workbook.stream.string, :filename => "#{@user.username}-#{@percentage}%-hashtags.xlsx" )    
    end
end
