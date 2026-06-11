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

    def test_default_assigns_description_to_summary
      schema = GrapeOAS.generate(app: SampleAPI, schema_type: :oas3)

      op = schema.dig("paths", "/users", "post")

      assert_equal "Create user", op["summary"]
      refute op.key?("description")
    end

    def test_backwards_compat_assigns_description_not_summary
      schema = GrapeOAS.generate(app: SampleAPI, schema_type: :oas3,
                                 grape_swagger_backwards_compat: true,)

      op = schema.dig("paths", "/users", "post")

      assert_equal "Create user", op["description"]
      refute op.key?("summary"), "summary should not be emitted in compat mode"
    end

    def test_default_uses_success_for_response_description
      schema = GrapeOAS.generate(app: SampleAPI, schema_type: :oas3)

      op = schema.dig("paths", "/users", "post")

      assert_equal "Success", op.dig("responses", "201", "description")
    end

    def test_backwards_compat_reuses_description_for_success_response
      schema = GrapeOAS.generate(app: SampleAPI, schema_type: :oas3,
                                 grape_swagger_backwards_compat: true,)

      op = schema.dig("paths", "/users", "post")

      assert_equal "Create user", op.dig("responses", "201", "description")
    end

    def test_backwards_compat_keeps_explicit_failure_message
      api_class = Class.new(Grape::API) do
        format :json
        desc "Create user" do
          failure [[422, "Unprocessable Entity"]]
        end
        params { requires :name, type: String }
        post "users" do
          {}
        end
      end

      schema = GrapeOAS.generate(app: api_class, schema_type: :oas3,
                                 grape_swagger_backwards_compat: true,)

      op = schema.dig("paths", "/users", "post")

      assert_equal "Unprocessable Entity", op.dig("responses", "422", "description")
    end
  end
end
