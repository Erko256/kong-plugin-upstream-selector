local helpers = require "spec.helpers"
local kong_client = require "kong_client.spec.test_helpers"

describe("UpstreamSelector", function()
    local kong_sdk, send_request, send_admin_request

    setup(function()
        helpers.start_kong({ custom_plugins = "upstream-selector" })

        kong_sdk = kong_client.create_kong_client()
        send_request = kong_client.create_request_sender(helpers.proxy_client())
        send_admin_request = kong_client.create_request_sender(helpers.admin_client())
    end)

    teardown(function()
        helpers.stop_kong(nil)
    end)

    before_each(function()
        helpers.db:truncate()
    end)

    context("Admin API", function()
        local service

        before_each(function()
            service = kong_sdk.services:create({
                name = "test-service",
                url = "http://mockbin:8080/request"
            })
        end)

        context('Plugin configuration', function()

            it('should return 201 when header name is given', function()
                local success, response = pcall(function()
                    kong_sdk.plugins:create({
                        service_id = service.id,
                        name = "upstream-selector",
                        config = {
                            header_name = "header_name"
                        }
                    })
                end)

                assert.is_true(success)
            end)

            it('should respond with error when header name is missing', function()
                local success, response = pcall(function()
                    kong_sdk.plugins:create({
                        service_id = service.id,
                        name = "upstream-selector",
                        config = {}
                    })
                end)

                assert.is_false(success)
            end)

        end)

    end)

end)
