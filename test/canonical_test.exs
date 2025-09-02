defmodule CanonicalTest do
  use ExUnit.Case

  alias Paradigm.Graph.{Canonical, MapGraph, Node}

  # Test structs
  defmodule Person do
    defstruct [:name, :age, :address, :company]
  end

  defmodule Address do
    defstruct [:street, :city, :state]
  end

  defmodule Company do
    defstruct [:name, :employees, :ceo]
  end

  describe "to_struct/2" do
    test "converts a simple node to struct" do
      graph = MapGraph.new()
      |> Paradigm.Graph.insert_node(%Node{id: "person1", class: Person, data: %{"name" => "John", "age" => 30}})

      result = Canonical.to_struct(graph, "person1")

      assert %Person{name: "John", age: 30, address: nil} = result
    end

    test "returns nil for non-existent node" do
      graph = MapGraph.new()

      result = Canonical.to_struct(graph, "nonexistent")

      assert result == nil
    end

    test "expands references to other nodes" do

      graph = MapGraph.new()
      |> Paradigm.Graph.insert_node(%Node{id: "address1", class: Address, data: %{"street" => "123 Main St", "city" => "Springfield", "state" => "IL"}})
      |> Paradigm.Graph.insert_node(%Node{id: "person1", class: Person, data: %{"name" => "John", "age" => 30, "address" => %Node.Ref{id: "address1"}}})

      result = Canonical.to_struct(graph, "person1")

      assert %Person{
        name: "John",
        age: 30,
        address: %Address{street: "123 Main St", city: "Springfield", state: "IL"}
      } = result
    end

    test "handles cycles by returning cycle marker" do
      # Create a cycle: person -> company -> person
      graph = MapGraph.new()
      |> Paradigm.Graph.insert_node(%Node{id: "person1", class: Person, data: %{"name" => "John", "company" => %Node.Ref{id: "company1"}}})
      |> Paradigm.Graph.insert_node(%Node{id: "company1", class: Company, data: %{"name" => "ACME Corp", "ceo" => %Node.Ref{id: "person1"}}})

      result = Canonical.to_struct(graph, "person1")

      # Should detect the cycle and insert a cycle marker
      assert %Person{name: "John"} = result
      assert is_map(result.company)
      assert result.company.name == "ACME Corp"
      assert result.company.ceo == %{__cycle_ref__: "person1"}
    end

    test "handles references in lists" do
      graph = MapGraph.new()
      |> Paradigm.Graph.insert_node(%Node{id: "person1", class: Person, data: %{"name" => "John", "age" => 30}})
      |> Paradigm.Graph.insert_node(%Node{id: "person2", class: Person, data: %{"name" => "Jane", "age" => 25}})
      |> Paradigm.Graph.insert_node(%Node{id: "company1", class: Company, data: %{
        "name" => "ACME Corp",
        "employees" => [%Node.Ref{id: "person1"}, %Node.Ref{id: "person2"}]
      }})

      result = Canonical.to_struct(graph, "company1")

      assert %Company{name: "ACME Corp", employees: employees} = result
      assert length(employees) == 2
      assert Enum.any?(employees, &(&1.name == "John"))
      assert Enum.any?(employees, &(&1.name == "Jane"))
    end

    test "returns raw data when struct module doesn't exist" do
      graph = MapGraph.new()
      |> Paradigm.Graph.insert_node(%Node{id: "unknown1", class: NonExistentModule, data: %{"foo" => "bar"}})

      result = Canonical.to_struct(graph, "unknown1")

      assert %{foo: "bar"} = result
    end
  end

  describe "struct_to_graph/3" do
    test "converts a simple struct to graph node" do
      graph = MapGraph.new()
      person = %Person{name: "John", age: 30}

      result = Canonical.struct_to_graph(graph, person, "person1")

      node = Paradigm.Graph.get_node(result, "person1")
      assert %Node{id: "person1", class: Person, data: %{"name" => "John", "age" => 30, "address" => nil, "company" => nil}} = node
    end

    test "converts nested structs to references" do
      address = %Address{street: "123 Main St", city: "Springfield", state: "IL"}
      person = %Person{name: "John", age: 30, address: address}

      graph = MapGraph.new()
      result = Canonical.struct_to_graph(graph, person, "person1")

      person_node = Paradigm.Graph.get_node(result, "person1")
      assert %Node{id: "person1", class: Person, data: person_data} = person_node
      assert person_data["name"] == "John"
      assert person_data["age"] == 30
      assert %Node.Ref{id: address_id} = person_data["address"]

      address_node = Paradigm.Graph.get_node(result, address_id)
      assert %Node{id: ^address_id, class: Address, data: address_data} = address_node
      assert address_data["street"] == "123 Main St"
      assert address_data["city"] == "Springfield"
      assert address_data["state"] == "IL"
    end

    test "handles structs with lists of structs" do
      person1 = %Person{name: "John", age: 30}
      person2 = %Person{name: "Jane", age: 25}
      company = %Company{name: "ACME Corp", employees: [person1, person2]}

      graph = MapGraph.new()
      result = Canonical.struct_to_graph(graph, company, "company1")

      company_node = Paradigm.Graph.get_node(result, "company1")
      assert %Node{id: "company1", class: Company, data: company_data} = company_node
      assert company_data["name"] == "ACME Corp"

      employees = company_data["employees"]
      assert is_list(employees)
      assert length(employees) == 2
      assert Enum.all?(employees, &match?(%Node.Ref{}, &1))

      # Check that employee nodes were created
      Enum.each(employees, fn %Node.Ref{id: emp_id} ->
        emp_node = Paradigm.Graph.get_node(result, emp_id)
        assert %Node{id: ^emp_id, class: Person} = emp_node
      end)
    end

    test "avoids infinite recursion with cycles" do
      # This test verifies that the same node_id isn't processed twice
      address = %Address{street: "123 Main St", city: "Springfield", state: "IL"}
      person = %Person{name: "John", age: 30, address: address}

      graph = MapGraph.new()

      # Insert the same struct twice with the same ID - should not cause issues
      result = Canonical.struct_to_graph(graph, person, "person1")
      result2 = Canonical.struct_to_graph(result, person, "person1")

      # Should have the same number of nodes
      nodes1 = Paradigm.Graph.get_all_nodes(result)
      nodes2 = Paradigm.Graph.get_all_nodes(result2)
      assert length(nodes1) == length(nodes2)
    end
  end

  describe "roundtrip conversion" do
    test "struct -> graph -> struct preserves data" do
      address = %Address{street: "123 Main St", city: "Springfield", state: "IL"}
      original_person = %Person{name: "John", age: 30, address: address}

      graph = MapGraph.new()
      |> Canonical.struct_to_graph(original_person, "person1")

      reconstructed_person = Canonical.to_struct(graph, "person1")

      assert reconstructed_person == original_person
    end

    test "roundtrip with complex nested structures" do
      person1 = %Person{name: "John", age: 30}
      person2 = %Person{name: "Jane", age: 25}
      original_company = %Company{name: "ACME Corp", employees: [person1, person2]}

      graph = MapGraph.new()
      |> Canonical.struct_to_graph(original_company, "company1")

      reconstructed_company = Canonical.to_struct(graph, "company1")

      assert reconstructed_company.name == original_company.name
      assert length(reconstructed_company.employees) == 2

      # Check employees are preserved (order might differ)
      names = Enum.map(reconstructed_company.employees, & &1.name)
      assert "John" in names
      assert "Jane" in names
    end
  end
end
