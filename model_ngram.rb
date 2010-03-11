class Ngram < ActiveRecord::Base
  def to_s
    s = "#{a} #{b} #{c} #{count}"
    s = "(h)" + s if head
    s += "(t)" if tail
    return s
  end
end

class Urihistory < ActiveRecord::Base

end
