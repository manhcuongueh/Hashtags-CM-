class ApiController < ApplicationController
    def user_json
        users = User.all
        render json: users
    end
    def hashtag_json
        username= params[:username]
        if  User.where(:username => username).present?
            user = User.find_by_username(username)
            hashtags = user.hashtags
            render json: hashtags
        else
            render json: "Your account is invalid or not available"
        end
    end
end
