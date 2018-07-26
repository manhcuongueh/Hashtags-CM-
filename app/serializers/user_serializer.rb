class UserSerializer < ActiveModel::Serializer
    attributes :id, :username, :date_start, :date_end
end