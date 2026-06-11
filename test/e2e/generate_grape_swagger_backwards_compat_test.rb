# frozen_string_literal: true

require "test_helper"

module GrapeOAS
  class GenerateGrapeSwaggerBackwardsCompatTest < Minitest::Test
    class SampleAPI < Grape::API
      format :json

      desc "Create user"
      params do
        requires :name, type: String
      end
      post "users" do
        {}
      end
    end

    def test_default_uses_snake_case_operation_id_and_request_suffix
      schema = GrapeOAS.generate(app: SampleAPI, schema_type: :oas3)

      op = schema.dig("paths", "/users", "post")

      assert_equal "post_users", op["operationId"]
      assert_equal "#/components/schemas/post_users_Request",
                   op.dig("requestBody", "content", "application/json", "schema", "$ref")
      assert_includes schema.dig("components", "schemas").keys, "post_users_Request"
    end

    def test_backwards_compat_uses_camel_case_operation_id_and_no_suffix
      schema = GrapeOAS.generate(app: SampleAPI, schema_type: :oas3,
                                 grape_swagger_backwards_compat: true,)

      op = schema.dig("paths", "/users", "post")

      assert_equal "postUsers", op["operationId"]
      assert_equal "#/components/schemas/postUsers",
                   op.dig("requestBody", "content", "application/json", "schema", "$ref")
      assert_includes schema.dig("components", "schemas").keys, "postUsers"
    end

    def test_backwards_compat_oas2_body_param_name
      schema = GrapeOAS.generate(app: SampleAPI, schema_type: :oas2,
                                 grape_swagger_backwards_compat: true,)

      op = schema.dig("paths", "/users", "post")

      assert_equal "postUsers", op["operationId"]
      body_param = op["parameters"].find { |p| p["in"] == "body" }

      assert_equal "postUsers", body_param["name"]
    end

    def test_backwards_compat_preserves_explicit_nickname
      api_class = Class.new(Grape::API) do
        format :json
        desc "Get user", nickname: "getUserById"
        get "users/:id" do
          {}
        end
      end

      schema = GrapeOAS.generate(app: api_class, schema_type: :oas3,
                                 grape_swagger_backwards_compat: true,)

      assert_equal "getUserById", schema.dig("paths", "/users/{id}", "get", "operationId")
    end
  end
end
