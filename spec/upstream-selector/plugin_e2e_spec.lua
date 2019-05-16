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

    describe("Admin API", function()
        local consumer

        before_each(function()
            consumer = kong_sdk.consumers:create({
                username = "test-consumer"
            })
        end)

        context("Plugin configuration", function()

            context("when header name is present", function()
                it("should create the plugin", function()
                    local success, _ = pcall(function()
                        kong_sdk.plugins:create({
                            consumer_id = consumer.id,
                            name = "upstream-selector",
                            config = {
                                header_name = "Test-Header"
                            }
                        })
                    end)

                    assert.is_true(success)
                end)
            end)

            context("when header name is missing", function()
                it("should respond with an error", function()
                    local success, _ = pcall(function()
                        kong_sdk.plugins:create({
                            consumer_id = consumer.id,
                            name = "upstream-selector",
                            config = {}
                        })
                    end)

                    assert.is_false(success)
                end)
            end)

        end)
    end)

    describe("Upstream selector", function()
        local service, route, plugin

        before_each(function()
            service = kong_sdk.services:create({
                name = "test-service",
                url = "http://mockbin:8080/request"
            })
            route = kong_sdk.routes:create_for_service(service.id, "/test-route")
            plugin = kong_sdk.services:add_plugin(service.id, {
                name = "upstream-selector",
                config = {
                    header_name = "Test-Header"
                }
            })
        end)

        context("when upstream is missing", function()
            it("should respond with error", function()
                local response = send_request({
                    method = "GET",
                    path = "/test-route",
                    headers = {
                        ["Test-Header"] = "NonExistingUpstream"
                    }
                })

                assert.are.equal(400, response.status)
            end)
        end)

        context("when header is missing", function()
            it("should do nothing", function()
                local response = send_request({
                    method = "GET",
                    path = "/test-route"
                })

                assert.are.equal(200, response.status)
            end)
        end)

    end)


end)