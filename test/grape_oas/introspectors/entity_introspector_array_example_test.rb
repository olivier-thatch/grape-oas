# frozen_string_literal: true

require "test_helper"

module GrapeOAS
  module Introspectors
    class EntityIntrospectorArrayExampleTest < Minitest::Test
      # is_array: true with an array-valued example — example belongs on the array wrapper.

      class ArrayExampleEntity < Grape::Entity
        expose :species, documentation: { type: "string", is_array: true, example: %w[cat dog] }
        expose :counts,  documentation: { type: "integer", is_array: true, example: [1, 2] }
      end

      def test_array_valued_string_example_is_placed_on_array_schema
        schema = EntityIntrospector.new(ArrayExampleEntity).build_schema
        species = schema.properties["species"]

        assert_equal Constants::SchemaTypes::ARRAY, species.type
        assert_equal %w[cat dog], species.examples
        assert_nil species.items.examples
      end

      def test_array_valued_integer_example_is_placed_on_array_schema
        schema = EntityIntrospector.new(ArrayExampleEntity).build_schema
        counts = schema.properties["counts"]

        assert_equal Constants::SchemaTypes::ARRAY, counts.type
        assert_equal [1, 2], counts.examples
        assert_nil counts.items.examples
      end

      # is_array: true with a scalar example — example stays on items (valid per OAS).

      class ScalarExampleOnArrayEntity < Grape::Entity
        expose :label, documentation: { type: "string", is_array: true, example: "cat" }
      end

      class NoExampleEntity < Grape::Entity
        expose :tags, documentation: { type: "string", is_array: true }
      end

      class EmptyArrayExampleEntity < Grape::Entity
        expose :tags, documentation: { type: "string", is_array: true, example: [] }
      end

      class ReferencedEntity < Grape::Entity
        expose :name, documentation: { type: "string" }
      end

      class SharedEntityExampleEntity < Grape::Entity
        expose :single, using: ReferencedEntity, documentation: { example: { "name" => "Ada" } }
        expose :list, using: ReferencedEntity,
                      documentation: { is_array: true, example: [{ "name" => "Ada" }, { "name" => "Lin" }] }
      end

      class ScalarExampleOnReferencedArrayEntity < Grape::Entity
        expose :plain, using: ReferencedEntity
        expose :list, using: ReferencedEntity, documentation: { is_array: true, example: { "name" => "Ada" } }
      end

      def test_scalar_example_on_is_array_exposure_stays_on_items
        schema = EntityIntrospector.new(ScalarExampleOnArrayEntity).build_schema
        label = schema.properties["label"]

        assert_equal Constants::SchemaTypes::ARRAY, label.type
        assert_nil label.examples
        assert_equal "cat", label.items.examples
      end

      def test_is_array_exposure_without_example_produces_no_examples
        schema = EntityIntrospector.new(NoExampleEntity).build_schema
        tags = schema.properties["tags"]

        assert_equal Constants::SchemaTypes::ARRAY, tags.type
        assert_nil tags.examples
        assert_nil tags.items.examples
      end

      def test_empty_array_example_is_placed_on_array_schema
        schema = EntityIntrospector.new(EmptyArrayExampleEntity).build_schema
        tags = schema.properties["tags"]

        assert_equal [], tags.examples
        assert_nil tags.items.examples
      end

      def test_array_example_does_not_mutate_shared_entity_schema
        schema = EntityIntrospector.new(SharedEntityExampleEntity).build_schema
        single = schema.properties["single"]
        list = schema.properties["list"]

        assert_equal({ "name" => "Ada" }, single.examples)
        assert_equal [{ "name" => "Ada" }, { "name" => "Lin" }], list.examples
        assert_nil list.items.examples
        refute_same single, list.items
      end

      def test_scalar_example_on_array_of_shared_entity_does_not_mutate_other_exposure
        schema = nil
        log = capture_grape_oas_log do
          schema = EntityIntrospector.new(ScalarExampleOnReferencedArrayEntity).build_schema
        end
        plain = schema.properties["plain"]
        list = schema.properties["list"]

        assert_nil plain.examples
        assert_nil list.examples
        assert_equal({ "name" => "Ada" }, list.items.examples)
        refute_same plain, list.items
        assert_match(/Duplicating cached schema/, log)
      end
    end
  end
end
