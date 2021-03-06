require 'test/common'
require 'typisch/typed'

describe "Typed" do

  before do
    @registry = Registry.new
  end

  it "should help you register a new object type for a class or module, registering it by default in the global registry and by a symbol corresponding to the class/module name" do
    Typisch.register do
      class Foo
        include Typed
        register_type do
          property :title, :string
          property :bar, :Bar
        end
      end

      module Bar
        include Typed
        register_type do
          property :title, :string
          property :foo, :Foo
        end
      end
    end

    # look them up in the global registry:
    foo_type, bar_type = Typisch[:Foo], Typisch[:Bar]

    assert_instance_of Type::Object, foo_type
    assert_equal Foo, foo_type.class_or_module

    # check the forward reference from one class to the next got hooked up OK
    assert_equal bar_type, foo_type[:bar]
    assert_equal foo_type, bar_type[:foo]

    assert_same Typisch[:Foo], Typisch[Foo]
    assert_same Typisch[:Bar], Typisch[Bar]
  end

  it "should let you specify which registry to register it in" do
    class Baz
      include Typed
      SPECIAL_REGISTRY = Typisch::Registry.new

      register_type(SPECIAL_REGISTRY) do
        property :title, :string
      end
    end

    baz_type = Baz::SPECIAL_REGISTRY[:Baz]
    assert_instance_of Type::Object, baz_type
    assert_equal Baz, baz_type.class_or_module
  end

  class Abc < TypedStruct
    register_type do
      property :prop1, nullable(:boolean)
      property :prop2, :sequence, :integer
    end
  end

  it "should let you type-check instances of the class as a whole" do
    assert Abc.new(:prop1 => true, :prop2 => [123]).type_check
    assert_raises(TypeError) {Abc.new(:prop1 => true, :prop2 => nil).type_check}
    assert_raises(TypeError) {Abc.new(:prop1 => 234, :prop2 => [123]).type_check}
    assert_raises(TypeError) {Abc.new(:prop1 => true).type_check}
  end

  it "should let you type-check individual properties" do
    assert Abc.new(:prop1 => true, :prop2 => [123]).type_check_property(:prop1)
    assert Abc.new(:prop1 => true, :prop2 => [123]).type_check_property(:prop2)

    assert_raises(TypeError) {Abc.new(:prop1 => 'hey', :prop2 => nil).type_check_property(:prop2)}
    assert Abc.new(:prop1 => true, :prop2 => 'oi').type_check_property(:prop1)

    assert_raises(TypeError) {Abc.new(:prop1 => 234, :prop2 => [123]).type_check_property(:prop1)}
    assert Abc.new(:prop1 => 234, :prop2 => [123]).type_check_property(:prop2)
  end

  it "should type-check shallowly by default" do
    assert Abc.new(:prop1 => true, :prop2 => ['only','checks','that','this','is','a','sequence']).type_check_property(:prop2)
    assert Abc.new(:prop1 => true, :prop2 => ['only','checks','that','this','is','a','sequence']).type_check_property(:prop1)
    assert Abc.new(:prop1 => true, :prop2 => ['only','checks','that','this','is','a','sequence']).type_check
  end

  it "should do a full type-check if you pass true for full_check" do
    assert_raises(TypeError) do
      assert Abc.new(:prop1 => true, :prop2 => ['checks','the','members','too']).type_check_property(:prop2, true)
    end
    assert_raises(TypeError) do
      assert Abc.new(:prop1 => true, :prop2 => ['checks','the','members','too']).type_check(true)
    end
  end

  it "should declare attributes on the class based on the properties of the object type" do
    abc = Abc.new
    assert_respond_to abc, :prop1
    assert_respond_to abc, :prop2
    abc.prop1 = true
    abc.prop2 = [1,2,3]
    assert_equal true, abc.prop1
    assert_equal [1,2,3], abc.prop2
  end

  it "should alias boolean or nullable boolean attributes with a question_marked? getter" do
    abc = Abc.new
    assert_respond_to abc, :prop1?
    abc.prop1 = true
    assert_equal true, abc.prop1?
    abc.prop1 = false
    assert_equal false, abc.prop1?
  end

  class Def < Abc
    register_subtype do
      property :prop3, :string
    end
  end

  it "should let you register a subtype for a subclass of a typed class" do
    assert Def.type < Abc.type
    assert Def.type_of(:prop3)
    assert_nil Abc.type_of(:prop3)
  end

  class Hjk
    include Typed
    register_type do
      property :x, :string
      property :y, :string
    end

    register_version_type(:x_only) do
      derive_property :x
    end

    register_version_type(:y_only) do
      derive_property :y
    end
  end

  class Lmn
    include Typed
    register_type do
      property :hjk, Hjk
      property :hjk2, :Hjk
    end

    register_version_type(:foo) do
      derive_property :hjk, :version => :x_only
      derive_property :hjk2, :version => :y_only
    end
  end

  it "should let you register version types derived from the main type registered for a class" do
    assert_equal [:x], Hjk.version_types[:x_only].property_names
    assert_equal [:y], Hjk.version_types[:y_only].property_names
    assert_equal Hjk, Hjk.version_types[:y_only].class_or_module
  end

  it "should let you specify just a :version when deriving from a type for a class for which versions have been registered; this will use that version type for the derived type" do
    assert_same Hjk.version_types[:x_only], Lmn.version_types[:foo][:hjk]
    assert_same Hjk.version_types[:y_only], Lmn.version_types[:foo][:hjk2]
  end
end
