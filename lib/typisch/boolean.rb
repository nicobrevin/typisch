module Typisch
  class Type::Boolean < Type::Constructor::Singleton
    def self.tag
      "Boolean"
    end

    def check_type(instance)
      instance == true || instance == false
    end

    Registry.register_global_type(:boolean, top_type)
  end
end
