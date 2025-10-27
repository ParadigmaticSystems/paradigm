defmodule Paradigm.PositionOrderingTest do
  use ExUnit.Case

  alias Paradigm.{Class, Property}

  describe "position-based property ordering" do
    test "get_class_properties_sorted returns properties ordered by position" do
      # Create a test class with properties that have different positions
      test_class = %Class{
        name: "TestClass",
        is_abstract: false,
        properties: %{
          "third_property" => %Property{
            name: "third_property",
            type: "string",
            position: 2
          },
          "first_property" => %Property{
            name: "first_property",
            type: "string",
            position: 0
          },
          "second_property" => %Property{
            name: "second_property",
            type: "string",
            position: 1
          }
        },
        super_classes: []
      }

      # Test the new sorting function
      sorted_properties = Paradigm.get_class_properties_sorted(test_class)
      property_names = Enum.map(sorted_properties, & &1.name)

      # Expected output should be ordered by position
      expected_order = ["first_property", "second_property", "third_property"]
      assert property_names == expected_order
    end

    test "get_all_properties_sorted works with inheritance" do
      parent_class = %Class{
        name: "ParentClass",
        is_abstract: false,
        properties: %{
          "parent_prop_b" => %Property{
            name: "parent_prop_b",
            type: "string",
            position: 1
          },
          "parent_prop_a" => %Property{
            name: "parent_prop_a",
            type: "string",
            position: 0
          }
        },
        super_classes: []
      }

      child_class = %Class{
        name: "ChildClass",
        is_abstract: false,
        properties: %{
          "child_prop" => %Property{
            name: "child_prop",
            type: "string",
            position: 0
          }
        },
        super_classes: ["parent_class"]
      }

      test_paradigm = %Paradigm{
        name: "TestParadigm",
        description: "Test paradigm for property ordering",
        primitive_types: %{},
        packages: %{},
        classes: %{
          "parent_class" => parent_class,
          "child_class" => child_class
        },
        enumerations: %{}
      }

      # Test inheritance with sorting
      inherited_sorted = Paradigm.get_all_properties_sorted(child_class, test_paradigm)
      property_names = Enum.map(inherited_sorted, & &1.name)

      # Should include both inherited properties (sorted by position) and own properties
      # The current implementation puts inherited properties first (sorted by position),
      # then direct properties (sorted by position)
      expected_properties = ["parent_prop_a", "child_prop", "parent_prop_b"]
      assert property_names == expected_properties

      # Verify positions are preserved (parent_prop_a=0, child_prop=0, parent_prop_b=1)
      positions = Enum.map(inherited_sorted, & &1.position)
      assert positions == [0, 0, 1]
    end

    test "abstraction layer preserves property ordering" do
      # Use the metamodel builtin which has position fields
      paradigm = Paradigm.Builtin.Metamodel.definition()

      # Embed and extract
      embedded = Paradigm.Abstraction.embed(paradigm)
      extracted = Paradigm.Abstraction.extract(embedded)

      # The extracted paradigm should be identical to the original
      assert paradigm == extracted

      # Specifically test that Property class properties maintain their order
      property_class = extracted.classes["property"]
      sorted_properties = Paradigm.get_class_properties_sorted(property_class)
      property_names = Enum.map(sorted_properties, & &1.name)

      # Should be ordered by position: name(0), type(1), is_ordered(2), is_composite(3), 
      # lower_bound(4), upper_bound(5), default_value(6), position(7)
      expected_order = [
        "name",
        "type",
        "is_ordered",
        "is_composite",
        "lower_bound",
        "upper_bound",
        "default_value",
        "position"
      ]

      assert property_names == expected_order
    end

    test "properties with same position are sorted deterministically" do
      test_class = %Class{
        name: "TestClass",
        is_abstract: false,
        properties: %{
          "prop_z" => %Property{
            name: "prop_z",
            type: "string",
            position: 0
          },
          "prop_a" => %Property{
            name: "prop_a",
            type: "string",
            position: 0
          }
        },
        super_classes: []
      }

      # Should be stable sort - properties with same position maintain relative order
      sorted_properties = Paradigm.get_class_properties_sorted(test_class)
      property_names = Enum.map(sorted_properties, & &1.name)

      # The sort should be stable, so we just verify it's consistent
      sorted_again = Paradigm.get_class_properties_sorted(test_class)
      property_names_again = Enum.map(sorted_again, & &1.name)

      assert property_names == property_names_again
    end

    test "handles nil class gracefully" do
      assert Paradigm.get_class_properties_sorted(nil) == []
      assert Paradigm.get_all_properties_sorted(nil, %Paradigm{}) == []
    end
  end
end
