# frozen_string_literal: true

require "test_helper"

module GrapeOAS
  module Exporter
    class OAS2ResponseTest < Minitest::Test
      def test_emits_empty_schema_when_no_entity
        schema = ApiModel::Schema.new
        media = ApiModel::MediaType.new(mime_type: "application/json", schema: schema)
        resp = ApiModel::Response.new(http_status: "200", description: "Success", media_types: [media])

        result = Exporter::OAS2::Response.new([resp]).build

        assert_empty(result["200"]["schema"])
      end

      def test_includes_headers_and_examples
        schema = ApiModel::Schema.new(type: "string")
        media = ApiModel::MediaType.new(mime_type: "application/json", schema: schema,
                                        examples: { "application/json" => { foo: "bar" } },)
        resp = ApiModel::Response.new(http_status: "200", description: "OK", media_types: [media],
                                      headers: [{ name: "X-Trace", schema: { "type" => "string" } }],)

        result = Exporter::OAS2::Response.new([resp]).build

        assert_equal "OK", result["200"]["description"]
        assert_equal({ "X-Trace" => { "type" => "string" } }, result["200"]["headers"])
        assert_equal({ "application/json" => { foo: "bar" } }, result["200"]["examples"])
      end

      def test_omits_examples_when_media_types_are_empty
        resp = ApiModel::Response.new(
          http_status: "204",
          description: "No Content",
          media_types: [],
          examples: { "application/json" => { deleted: true } },
        )

        result = Exporter::OAS2::Response.new([resp]).build

        refute result["204"].key?("schema")
        refute result["204"].key?("examples")
      end
    end
  end
end
