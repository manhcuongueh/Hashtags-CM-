class User < ApplicationRecord
    has_many :hashtags, dependent: :destroy
end
