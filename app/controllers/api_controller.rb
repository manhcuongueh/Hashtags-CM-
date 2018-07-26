class ApiController < ApplicationController
    def user_json
        users = User.all
        render json: users
    end
    def hashtag_json
        username= params[:username]
        user = User.find_by_username(username)
        hashtags = user.hashtags
        render json: hashtags
    end
end
