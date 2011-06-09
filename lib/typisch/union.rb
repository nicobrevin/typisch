module Typisch
  class Type::Union < Type
    attr_reader :alternative_types, :alternative_types_by_class

    class << self
      private :new
      
      def union(*types)
        # Use the special Type::Nothing singleton
        # for an empty union. (Nothing is just an empty union,
        # except with a special name).
        return Type::NOTHING if types.length == 0
        
        # Not much point in a union with only one clause
        return types.first if types.length == 1
        
        # Expand any unions amongst the constituent types
        # (we only need to do this one level deep, as
        # any unions will have been flattened themselves
        # due to this precondition)
        types.map! {|t| if t.is_a?(Type::Union) then t.alternative_types else [t] end}.flatten!(1)

        # We now have only Type::Tagged types, no union types;
        # group them by their Type::Tagged subclass and then
        # get the respective subclasses to consolidate the alternatives
        # of that class into a least upper bound (or list of 
        # non-overlapping alternative least upper bounds for a
        # tagged union):
        by_class = types.group_by(&:class)
        by_class.each do |klass, types|
          types.replace(klass.least_upper_bounds_for_union(*types))
        end

        # again this may have reduced us down to just a single type;
        # if so, return it, otherwise return a Union.
        if by_class.length == 1
          types = by_class.values.first
          return types.first if types.length == 1
        end
        
        new(by_class)
      end
    end

    def initialize(alternative_types_by_class)
      @alternative_types_by_class = alternative_types_by_class
      @alternative_types = alternative_types_by_class.values.flatten(1)
    end

    def to_s
      @alternative_types.join(' | ')
    end
  end
  
  # The Nothing (or 'bottom') type is just an empty Union:
  class Type::Nothing < Type::Union
    def initialize
      super({})
    end
    
    def to_s
      "Nothing"
    end

    Type::NOTHING = new
  end
  
  # The Any (or 'top') type is just a union of all the top types of the various Type::Tagged
  # subclasses:
  class Type::Any < Type::Union
    def initialize
      top_tagged_types = {}
      Tagged::TAGGED_TYPE_SUBCLASSES.each do |klass|
        top_tagged_types[klass] = [klass.top_type(self)]
      end
      super(top_tagged_types)
    end
    
    def to_s
      "Any"
    end
    
    Type::ANY = new
  end
end