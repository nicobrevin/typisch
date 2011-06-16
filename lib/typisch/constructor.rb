module Typisch
  # All types except Top, Bottom and Unions (which may necessarily involve more than one constructor type) have a
  # tag associated with them which is used at runtime to distinguish its instances somewhat from instances
  # of other types.
  #
  # This is an abstract superclass; each subclass of Type::Constructor is assumed to implement its own, distinct
  # lattice of types. For simple atomic types like Bool, there will only be one tag, "Bool", in that lattice.
  #
  # While the type lattices of different subclass of Type::Constructor are non-overlapping, within a subclass
  # (such as Type::Object or Type::Numeric) there may be a non-trivial type lattice, eg for Numeric,
  # Int < Float, and for Object, the type lattice is based on a nominal tag inheritance hierarchy in
  # the host language together with structural subtyping rules for object properties.
  #
  # A list of 'reserved tags' is maintained globally, and any Type::Constructor subtype which allows custom
  # user-specified tags to be used should ensure that they don't match any reserved tags.
  class Type::Constructor < Type
    CONSTRUCTOR_TYPE_SUBCLASSES = []

    class << self
      def inherited(subclass)
        # we add any non-abstract subclasses to this list, which is used to
        # construct the Any type. For now Constructor::Singleton is the only
        # other abstract Type::Constructor subclass:
        unless subclass == Type::Constructor::Singleton
          CONSTRUCTOR_TYPE_SUBCLASSES << subclass
        end
        super
      end

      # This should be the top in the type lattice for this class of taged types.
      # Its tag should be the top_tag above.
      # You are passed the overall_top, ie the top type of the overall type lattice,
      # to use; this is needed by parameterised types which want to parameterise their
      # top type by the overall top, eg Top = Foo | Bar | Sequence[Top] | ...
      def top_type(overall_top)
        raise NotImplementedError
      end

      # This gets called by the subtyper on a Type::Constructor subclass, with two instances of
      # that subclass.
      # It should return true or false; if it needs to check some subgoals,
      # say on child types of the ones passed in, it should use the supplied
      # 'recursively_check_subtype' block rather than calling itself recursively
      # directly. Doing it this way means you get all the co-recursive backtracking
      # goodness of the subtyper for free.
      def check_subtype(x, y, &recursively_check_subtype)
        raise NotImplementedError
      end
    end

    # the tag of this particular type
    def tag
      raise NotImplementedError
    end

    def to_s
      tag
    end

    # these are here so as to implement a common interface with Type::Union
    def alternative_types
      [self]
    end

    # A class of constructor type of which there is only one type, and
    # hence only one tag.
    #
    # Will have no supertype besides Any, and no subtype besides
    # Nothing.
    #
    # (abstract superclass; see Boolean or Null for example subclasses).
    class Singleton < Type::Constructor
      class << self
        private :new

        def tag
          raise NotImplementedError
        end

        def top_type(*)
          @top_type ||= new
        end

        def check_subtype(x, y)
          true
        end
      end

      def tag
        self.class.tag
      end
    end
  end
end
