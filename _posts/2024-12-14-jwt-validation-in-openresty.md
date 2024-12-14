---
layout: post
title: JWT Validation in OpenResty
categories: [OpenResty, Security]
excerpt: Learn how to validate JSON Web Tokens (JWT) in OpenResty using the lua-resty-jwt library. This post covers the basics of JWT, token validation, and how to integrate JWT validation into your OpenResty application.
---

# Introduction

JSON Web Tokens (JWTs) are a popular choice for securing communications in web applications. When working with NGINX, validating these tokens can be challenging, especially when dealing with certificate chains. This guide walks you through an implementation of a Lua-based JWT validator that integrates with NGINX and OpenResty. We’ll explore the key concepts, walk through each component of the implementation, and provide a comprehensive explanation of the accompanying test cases.

By the end of this post, you'll have a solid understanding of how to build a robust JWT validation system that supports certificate chains, enhancing the security of your NGINX deployment.

# What is a JSON Web Token (JWT)?

A JSON Web Token (JWT) is an open standard (RFC 7519) that defines a compact and self-contained way to securely transmit information between parties as a JSON object. JWTs are commonly used to authenticate users and exchange information between services. A JWT consists of three parts:

1. **Header**: Contains metadata about the token, such as the type of token and the signing algorithm used.
2. **Payload**: Contains the claims (statements) about the entity (user) and additional data.
3. **Signature**: Ensures the integrity of the token and verifies that the sender is who they claim to be.

The JWT is encoded and signed using a secret key or a public/private key pair. The signature is used to verify that the sender of the JWT is who they claim to be and to ensure that the message wasn't tampered with.  In order to validate the signature of a JWT, you need to have the secret key or the public key that corresponds to the private key used to sign the token.

# Using a Certificate Chain To Validate JWTs

I was recently in a situation where I wanted to validate JWT signatures coming from many different sources.  Each of these sources has its certificate.  Rather than ensuring that I maintain a secure and up-to-date mapping of certificate to source I setup a certificate chain.  I generated a `Root CA`, generated an `Intermediate CA`, and then generated a `Leaf CA` for each source.  Each of these leaf certificates was signed by the intermediate certificate and the intermediate certificate was signed by the root certificate.  This way I only needed to trust the root certificate and I could validate the JWTs from any source that had a leaf certificate signed by the intermediate certificate.  I accomplished this by having each source send it's public key along with the JWT.  I then validated the JWT using the public key and the certificate chain. 

# Implementing JWT Validation in OpenResty

I wanted to implement this in OpenResty so that all of the security logic took place at the proxy level, not the application level.  This will go a long was to help with scalability and reduce load on my application servers.

## Prerequisites

You'll need a few luarocks to get started.  Here is a Dockerfile that I used to run my tests in.

```plaintext
FROM openresty/openresty:alpine-fat

# Install dependencies for building C extensions
RUN apk add --no-cache \
    build-base \
    openssl \
    git \
    luarocks

RUN luarocks install busted \
    && luarocks install lua-resty-jwt \
    && luarocks install luassert \
    && luarocks install lua-resty-openssl \
    && luarocks install say

# Set the working directory for the app
WORKDIR /app

COPY jwt_operations.spec.lua /app
COPY jwt_operations.lua /app

# Run the Busted tests and fail if any of them fail
CMD ["resty", "-I", "/usr/local/openresty/luajit/share/lua/5.1/", "/app/jwt_operations.spec.lua"]
```

The CMD for this Dockerfile runs the tests from within an OpenResty runtime using the `resty` command.  This is required because the `lua-rest-jwt` and `lua-resty-openssl` libraries are not pure lua and require the OpenResty runtime to run.  We also install `openssl` into the container so that `lua-resty-openssl` has the libraries required to build itself.

## The JWT Validation Library

I create a lua module that contains the logic for validating the JWT.  Here is the entire module:

```lua
local _M = {}

--- Creates a new instance of the JWT Validator module.
-- @param deps (table) Optional dependencies to inject.
-- @return (table) The new instance of the JWT Validator module.
function _M.new(deps)
    deps = deps or {}
    local log = deps.log or require("my_logger")
    local env = deps.env or require("env_source")
    local jwt = deps.jwt or require("resty.jwt")
    local x509 = deps.x509 or require('resty.openssl.x509')
    local store = deps.store or require('resty.openssl.x509.store')

    local self = {
        log = log,
        env = env,
        jwt = jwt,
        x509 = x509,
        store = store,
        root_cert = deps.root_cert,
        intermediate_certs = deps.intermediate_certs or {}
    }

    --- Reads, decodes, and validates a JWT against a public key and certificate chain.
    -- @tparam string signature The JWT token to be validated.
    -- @tparam string client_cert The leaf certificate (in PEM format) from the client.
    -- @treturn true|table|nil if the JWT is valid and the payload if valid, nil if invalid
    -- @treturn false|nil|string error message if the JWT is invalid
    function self.validate_jwt_with_cert_chain(signature, client_cert)
        self.log.info("Starting JWT validation with certificate chain...")

        -- Validate inputs
        if not signature or type(signature) ~= "string" then
            self.log.error("Invalid signature: Must be a non-nil string")
            return false, nil, "Missing or invalid JWT token"
        end

        if not client_cert or type(client_cert) ~= "string" then
            self.log.error("Invalid client certificate PEM: Must be a non-nil string")
            return false, nil, "Missing or invalid client certificate PEM"
        end

        self.log.info("signature and client_cert inputs are not nil and are strings")

        -- Load the root certificate (trusted CA)
        local root_x509, err = self.x509.new(self.root_cert)
        if not root_x509 then
            return false, nil, "Failed to load root certificate: " .. (err or "Unknown error")
        end

        self.log.info("Root certificate loaded successfully")

        -- Convert intermediate PEMs into X.509 objects
        local intermediate_x509s = {}
        for _, intermediate_pem in ipairs(self.intermediate_certs) do
            local intermediate_cert, ierr = self.x509.new(intermediate_pem)
            if not intermediate_cert then
                self.log.error("Failed to load intermediate certificate: " .. (ierr or "Unknown error"))
                return false, nil, "Failed to load intermediate certificate"
            else
                table.insert(intermediate_x509s, intermediate_cert)
            end
        end

        self.log.info("Intermediate certificates loaded successfully")

        -- Load the client (leaf) certificate
        local leaf_x509, err = self.x509.new(client_cert)
        if not leaf_x509 then
            return false, nil, "Failed to load client (leaf) certificate: " .. (err or "Unknown error")
        end

        self.log.info("Leaf certificate loaded successfully")

        -- Create an X.509 store
        local store, err = self.store.new()
        if not store then
            return false, nil, "Failed to create X.509 store: " .. (err or "Unknown error")
        end

        -- Add the root certificate to the store
        local ok, err = store:add(root_x509)
        if not ok then
            return false, nil, "Failed to add root certificate to the store: " .. (err or "Unknown error")
        end

        self.log.info("Root certificate added to store")

        -- Add all intermediate certificates to the store
        for _, cert in ipairs(intermediate_x509s) do
            ok, err = store:add(cert)
            if not ok then
                self.log.error("Failed to add intermediate certificate: " .. (err or "unknown"))
                return false, nil, "Failed to add intermediate certificate to the store: " .. (err or "Unknown error")
            end
        end

        self.log.info("Intermediate certificates added to store.  Verifying certificate chain against leaf certificate...")

        -- Verify the leaf certificate
        local verified, verr = store:verify(leaf_x509)
        if not verified then
            self.log.error("Client certificate verification failed: " .. (verr or "unknown"))
            return false, nil, "Client certificate verification failed: " .. (verr or "Unknown error")
        end

        self.log.info("Certificate chain verified successfully")

        -- Verify the JWT signature using the public key
        local success, decoded_jwt, jwt_err = self.decode_jwt(signature)
        if not success then
            return false, nil, "Failed to decode JWT: " .. (jwt_err or "Unknown error")
        end

        local result = self.jwt:verify_jwt_obj(client_cert, decoded_jwt)

        if not result
        then
            self.log.error("JWT verification failed: Unknown error")
            return false, nil, "JWT verification failed: Unknown error"
        end

        if not result.verified or not result.valid
        then
            self.log.error("JWT validation failed: " .. (result.reason or "Unknown error"))
            return false, nil, "JWT validation failed: " .. (result.reason or "Unknown error")
        end

        self.log.info("JWT successfully verified")
        return true, decoded_jwt, nil
    end

    --- Decodes a JWT without verifying it. This can be used to inspect its payload.
    -- @tparam string token The JWT token to be decoded.
    -- @treturn boolean true if the JWT is successfully decoded
    -- @treturn table|nil decoded JWT payload if valid, nil if invalid
    -- @treturn string|nil error message if the JWT is invalid
    function self.decode_jwt(token)
        self.log.info("Starting JWT decode...")

        if not token or type(token) ~= "string" then
            self.log.error("Invalid token: Must be a non-nil string")
            return false, nil, "Missing or invalid JWT token"
        end

        local jwt_obj = self.jwt:load_jwt(token)
        if jwt_obj.valid then
            self.log.info("JWT successfully decoded")
            return true, jwt_obj, nil
        else
            self.log.error("Failed to decode JWT: " .. (jwt_obj.reason or "Unknown error"))
            return false, nil, "Failed to decode JWT: " .. (jwt_obj.reason or "Unknown error")
        end
    end

    return self
end

return _M
```

There's a lot going on here so let's break it down.

* **Dependencies**: The module accepts dependencies as an argument, allowing you to inject mocks or stubs for testing. The dependencies include a logger, environment source, JWT library, X.509 library, and X.509 store library.

```lua
deps = deps or {}
    local log = deps.log or require("my_logger")
    local env = deps.env or require("env_source")
    local jwt = deps.jwt or require("resty.jwt")
    local x509 = deps.x509 or require('resty.openssl.x509')
    local store = deps.store or require('resty.openssl.x509.store')

    local self = {
        log = log,
        env = env,
        jwt = jwt,
        x509 = x509,
        store = store,
        root_cert = deps.root_cert,
        intermediate_certs = deps.intermediate_certs or {}
    }
```

Why did I do it this way?  I wanted to be able to inject mocks for testing.  This way I can test the module in isolation without having to worry about the dependencies.  When this code runs from within OpenResty, the dependencies will be loaded as expected.  When I run my tests, I can inject mocks for the dependencies.

* **Start with Simple Validation**: We start by simply validating that the inputs are present and look like they should.

```lua
 -- Validate inputs
 if not signature or type(signature) ~= "string" then
     self.log.error("Invalid signature: Must be a non-nil string")
     return false, nil, "Missing or invalid JWT token"
 end

 if not client_cert or type(client_cert) ~= "string" then
     self.log.error("Invalid client certificate PEM: Must be a non-nil string")
     return false, nil, "Missing or invalid client certificate PEM"
 end

 self.log.info("signature and client_cert inputs are not nil and are strings")
```

* **Load Root Certificate and Certificate Chains**: We load the root certificate (trusted CA) and check for errors.  We then load the intermediate certificates and check for errors.

```lua
 -- Load the root certificate (trusted CA)
 local root_x509, err = self.x509.new(self.root_cert)
 if not root_x509 then
     return false, nil, "Failed to load root certificate: " .. (err or "Unknown error")
 end

 self.log.info("Root certificate loaded successfully")

 -- Convert intermediate PEMs into X.509 objects
 local intermediate_x509s = {}
 for _, intermediate_pem in ipairs(self.intermediate_certs) do
     local intermediate_cert, ierr = self.x509.new(intermediate_pem)
     if not intermediate_cert then
         self.log.error("Failed to load intermediate certificate: " .. (ierr or "Unknown error"))
         return false, nil, "Failed to load intermediate certificate"
     else
         table.insert(intermediate_x509s, intermediate_cert)
     end
 end

 self.log.info("Intermediate certificates loaded successfully")
```

This part uses the `x509` library that comes from the `lua-resty-openssl` library.  This library is a wrapper around the `openssl` library and provides a lot of the same functionality.  We use this library to load the certificates and then add them to a store.

* **Load the Leaf Certificate**: We load the leaf certificate and check for errors.

```lua
 -- Load the client (leaf) certificate
 local leaf_x509, err = self.x509.new(client_cert)
 if not leaf_x509 then
     return false, nil, "Failed to load client (leaf) certificate: " .. (err or "Unknown error")
 end

 self.log.info("Leaf certificate loaded successfully")
```

The `leaf certificate` is another word for the client certificate.  This is the certificate that was signed by the intermediate certificate and that was sent along with the JWT in a request header.

* **Setup the OpenSSL Store With The Certificate Chain**: We create an `X.509 store` and add the root certificate and all intermediate certificates to it.

```lua
-- Create an X.509 store
local store, err = self.store.new()
if not store then
    return false, nil, "Failed to create X.509 store: " .. (err or "Unknown error")
end

-- Add the root certificate to the store
local ok, err = store:add(root_x509)
if not ok then
    return false, nil, "Failed to add root certificate to the store: " .. (err or "Unknown error")
end

self.log.info("Root certificate added to store")

-- Add all intermediate certificates to the store
for _, cert in ipairs(intermediate_x509s) do
    ok, err = store:add(cert)
    if not ok then
        self.log.error("Failed to add intermediate certificate: " .. (err or "unknown"))
        return false, nil, "Failed to add intermediate certificate to the store: " .. (err or "Unknown error")
    end
end

self.log.info("Intermediate certificates added to store.  Verifying certificate chain against leaf certificate...")
```

At this point we have a `x509 store` that contains the root certificate and all intermediate certificates.  We can now use this store to verify the leaf certificate.

* **Verify the Certificate Chain**: We verify the leaf certificate against the certificate chain.

```lua
 -- Verify the leaf certificate
 local verified, verr = store:verify(leaf_x509)
 if not verified then
     self.log.error("Client certificate verification failed: " .. (verr or "unknown"))
     return false, nil, "Client certificate verification failed: " .. (verr or "Unknown error")
 end

 self.log.info("Certificate chain verified successfully")
```

At this point we know that the certificate that was sent along with the JWT is valid and was signed by the intermediate certificate.  Technically this doesn't tell us much since the leaf certificate is a public key.  So now we need to verify that the JWT was signed by the private key that corresponds to the public key in the leaf certificate.

7. **Verify the JWT Signature**: We verify the JWT signature using the public key from the leaf certificate.

```lua
 -- Verify the JWT signature using the public key
 local success, decoded_jwt, jwt_err = self.decode_jwt(signature)
 if not success then
     return false, nil, "Failed to decode JWT: " .. (jwt_err or "Unknown error")
 end

 local result = self.jwt:verify_jwt_obj(client_cert, decoded_jwt)

 if not result
 then
     self.log.error("JWT verification failed: Unknown error")
     return false, nil, "JWT verification failed: Unknown error"
 end

 if not result.verified or not result.valid
 then
     self.log.error("JWT validation failed: " .. (result.reason or "Unknown error"))
     return false, nil, "JWT validation failed: " .. (result.reason or "Unknown error")
 end

 self.log.info("JWT successfully verified")
 return true, decoded_jwt, nil
```

Here is the code for `self.decode_jwt`:

```lua
 --- Decodes a JWT without verifying it. This can be used to inspect its payload.
 -- @tparam string token The JWT token to be decoded.
 -- @treturn boolean true if the JWT is successfully decoded
 -- @treturn table|nil decoded JWT payload if valid, nil if invalid
 -- @treturn string|nil error message if the JWT is invalid
 function self.decode_jwt(token)
    self.log.info("Starting JWT decode...")
     
    if not token or type(token) ~= "string" then
       self.log.error("Invalid token: Must be a non-nil string")
       return false, nil, "Missing or invalid JWT token"
    end
     
    local jwt_obj = self.jwt:load_jwt(token)
     
    if jwt_obj.valid then
       self.log.info("JWT successfully decoded")
       return true, jwt_obj, nil
    else
       self.log.error("Failed to decode JWT: " .. (jwt_obj.reason or "Unknown error"))
       return false, nil, "Failed to decode JWT: " .. (jwt_obj.reason or "Unknown error")
    end
     
 end
return self
```

The first part of this function decodes the jwt.  The input for this is just the JWT signature.  This will return a `jwt_obj` that contains the decoded JWT.  The second part of this function verifies the JWT.  This doesn't do any sort of verification on the signature.  That happens when we call `self.jwt:verify_jwt_obj(client_cert, decoded_jwt)`.  What we pass in there is the leaf certificate and the decoded JWT.  This will return a `result` object that contains the verification results.  Which we check for errors then return.

# Testing the JWT Validation Library

Normally I would use `busted` when testing lua code.  However since this code requires the OpenResty runtime to run I had to use a different approach.  I used the Dockerfile at the beginning of this post to run the tests.  Here is the `spec/jwt_operations.spec.lua` file mentioned in the Dockerfile:

```lua
-- Import required libraries
local assert = require("luassert")
local spy = require("luassert.spy")

-- Import the module we are testing
local jwt_operations = require("jwt_operations")

-- Function to run a test and print the results
local function run_test(test_name, test_function)
    print("\n[TEST] Running: " .. test_name)
    local success, err = pcall(test_function)
    if success then
        print("[PASS] " .. test_name)
    else
        print("[FAIL] " .. test_name .. " - Error: " .. err)
    end
end

-- Test Suite
local function run_tests()
    -- Initialize shared variables
    local jwt_validator_instance
    local log_mock
    local env_source_mock

    local test_root_cert = [[
-----BEGIN CERTIFICATE-----
    EXAMPLE CERTIFICATE
-----END CERTIFICATE-----
    ]]

    local test_intermediate_cert = [[
-----BEGIN CERTIFICATE-----
    EXAMPLE CERTIFICATE
-----END CERTIFICATE-----
    ]]

    local test_leaf_cert = [[
-----BEGIN CERTIFICATE-----
    EXAMPLE CERTIFICATE
-----END CERTIFICATE-----
    ]]

    local test_leaf_private_key = [[
-----BEGIN RSA PRIVATE KEY-----
    EXAMPLE PRIVATE KEY
-----END RSA PRIVATE KEY-----
    ]]


    local test_wrongly_signed_leaf_cert = [[
    -----BEGIN CERTIFICATE-----
    EXAMPLE CERTIFICATE
-----END CERTIFICATE-----
    ]]

    local test_wrongly_signed_leaf_private_key = [[
-----BEGIN RSA PRIVATE KEY-----
    EXAMPLE PRIVATE KEY
-----END RSA PRIVATE KEY-----
    ]]

    -- Before each test setup
    local function before_each()
        log_mock = {
            info = spy.new(function(msg) print("[LOG] ", msg) end),
            error = spy.new(function(msg) print("[ERROR] ", msg) end)
        }

        env_source_mock = {}

        jwt_validator_instance = jwt_operations.new({
            log = log_mock,
            env = env_source_mock,
            root_cert = test_root_cert,
            intermediate_certs = {
                test_intermediate_cert
            }
        })
    end

    -- Test Cases
    local function test_should_successfully_decode_a_valid_jwt()
        before_each()
        local valid_jwt = "eyJhbGciOiJSUzI1NiJ9.eyJuYW1lIjoiUHJpbWFyeSBQb2QiLCJ0ZW5hbnROYW1lIjoidGVuYW50MTIzIiwidHlwZSI6IlhJTUFfU0VSVklDRSIsImVtYWlsIjoiIiwieGltYVNlcnZpY2VEZXRhaWxzSnNvbiI6eyJ0eXBlIjoiUFJJTUFSWV9QT0QifX0.hK38CZCs24ZVY-oEkYTxY7Pb3dUy4OjrJbBqZCt8ZLqYgRd9OrNLbhymggFiAsyEQ6D_jF0TUUD0fcvJs1eboGCVr5NsTICl-yIUV6WS8G8gwCY-Ir7bQsCUekDrfJMQwUvsPRWWL-zL4LNE6zRLR4gBQnC0eyA-IRatCzZg712O2R6jAvDH7fWREeuclo9Bi3lDO6rW6IKJvV5YHw4RkYTpILbx08rfGDkoWRguOSFw_9vyNeyII2-YiVZnSr7mJOCM2Y3ICFecuD80IFKSRa_OxBqMZoCpyJw7yKyaTzIE7HfoCT72nh-LPYmRNWgdgeBhrnlYoaegKEfD7thtmw"
        local is_valid, payload, err = jwt_validator_instance.decode_jwt(valid_jwt)
        assert.is_true(is_valid, "Expected JWT to be valid")
        assert.is_not_nil(payload, "Expected payload to be present")
        assert.is_nil(err, "Expected no error to be present")
    end

    local function test_should_fail_to_decode_an_invalid_jwt()
        before_each()
        local invalid_jwt = "invalid.jwt.token"
        local is_valid, payload, err = jwt_validator_instance.decode_jwt(invalid_jwt)
        assert.is_false(is_valid, "Expected JWT to be invalid")
        assert.is_nil(payload, "Expected no payload to be present")
        assert.is_not_nil(err, "Expected an error to be present")
    end

    local function test_should_validate_a_jwt_with_a_valid_certificate_chain()
        before_each()
        local jwt = require("resty.jwt")
        local table_data = {
            header = {typ = "JWT", alg = "RS256"},
            payload = {
                name = "Service Name",
                serviceInfo = {
                    type = "Awesome Backend"
                }
            }
        }

        local jwt_token = jwt:sign(test_leaf_private_key, table_data)
        local is_valid, payload, err = jwt_validator_instance.validate_jwt_with_cert_chain(jwt_token, test_leaf_cert)
        assert.is_true(is_valid, "Expected JWT to be valid with a proper certificate chain")
        assert.is_not_nil(payload, "Expected payload to be present")
        assert.is_nil(err, "Expected no error to be present")
    end

    local function test_should_fail_validation_if_the_jwt_signature_is_invalid()
        before_each()
        local jwt = require("resty.jwt")
        local table_data = {
            header = {typ = "JWT", alg = "RS256"},
            payload = {
                name = "Service Name",
                serviceInfo = {
                    type = "Awesome Backend"
                }
            }
        }

        local jwt_token = jwt:sign(test_wrongly_signed_leaf_private_key, table_data)
        local is_valid, payload, err = jwt_validator_instance.validate_jwt_with_cert_chain(jwt_token, test_leaf_cert)
        assert.is_false(is_valid, "Expected JWT to be invalid due to tampered signature")
        assert.is_nil(payload, "Expected no payload to be present")
        assert.is_not_nil(err, "Expected an error to be present")
    end

    -- Run all the tests
    run_test("should successfully decode a valid JWT", test_should_successfully_decode_a_valid_jwt)
    run_test("should fail to decode an invalid JWT", test_should_fail_to_decode_an_invalid_jwt)
    run_test("should validate a JWT with a valid certificate chain", test_should_validate_a_jwt_with_a_valid_certificate_chain)
    run_test("should fail validation if the JWT signature is invalid", test_should_fail_validation_if_the_jwt_signature_is_invalid)
end

-- Run all tests
run_tests()

```

These certificates I put in here I generated with XCA, a GUI tool to manage certificates. You can use any other tool to generate your certificates.  These are simple self-signed certificates suitable for testing only.

Now, let's run the tests:

```bash
docker build -t lua_jwt_tests .
docker run -it --rm lua_jwt_tests
```

You should see the following output:

```bash
[TEST] Running: should successfully decode a valid JWT
[LOG] Starting JWT decode...
[LOG] JWT successfully decoded
[PASS] should successfully decode a valid JWT

[TEST] Running: should fail to decode an invalid JWT
[LOG] Starting JWT decode...
[ERROR] Failed to decode JWT: invalid header: invalid
[PASS] should fail to decode an invalid JWT

[TEST] Running: should validate a JWT with a valid certificate chain
[LOG] Starting JWT validation with certificate chain...
[LOG] signature and client_cert inputs are not nil and are strings
[LOG] Root certificate loaded successfully
[LOG] Intermediate certificates loaded successfully
[LOG] Leaf certificate loaded successfully
[LOG] Root certificate added to store
[LOG] Intermediate certificates added to store.  Verifying certificate chain against leaf certificate...
[LOG] Certificate chain verified successfully
[LOG] Starting JWT decode...
[LOG] JWT successfully decoded
[LOG] JWT successfully verified
[PASS] should validate a JWT with a valid certificate chain

[TEST] Running: should fail validation if the JWT signature is invalid
[LOG] Starting JWT validation with certificate chain...
[LOG] signature and client_cert inputs are not nil and are strings
[LOG] Root certificate loaded successfully
[LOG] Intermediate certificates loaded successfully
[PASS] should fail validation if the JWT signature is invalid
```

The tests are passing. We have successfully implemented the JWT validation logic in Lua.