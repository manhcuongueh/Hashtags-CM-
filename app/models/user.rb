class User < ApplicationRecord
    has_many :hashtags, dependent: :destroy
    has_many :percentages, dependent: :destroy
    
end
