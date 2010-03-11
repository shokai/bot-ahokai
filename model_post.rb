class Post < ActiveRecord::Base
  def to_s
    return  "#{time} #{message} #{uri}"
  end
end
