class StatusController < ApplicationController
    def index
        @statuses  = Status.all
    end
    def delete
        Status.destroy_all
        redirect_to status_path
    end
end
