# APPROOV QUICKSTART - MULESOFT API GATEWAY

[Approov](https://approov.io) is an API security solution used to verify that requests received by your API services originate from trusted versions of your mobile apps.

This repo implements the Approov API request verification for the [Mulesoft API Gateway](https://aws.amazon.com/api-gateway/), which performs the verification check on the Approov Token before allowing valid traffic to reach the API endpoint.


If you are looking for another Approov integration you can check our list of [quickstarts](https://approov.io/docs/latest/approov-integration-examples/backend-api/), and if you don't find what you are looking for, then please let us know [here](https://approov.io/contact).


## Approov Integration Quickstart

The quickstart assumes that you already have an Mulesoft API Gateway running, and that you are familiar with the options for applying changes. If you are not familiar with the Mulesoft API Gateway then you may want to follow the step by step [Mulesoft API Gateway Example](docs/MULESOFT_API_GATEWAY_EXAMPLE.md) instead.

The quickstart was tested with the following Operating Systems:

* Ubuntu 20.04
* MacOS Big Sur
* Windows 10 WSL2 - Ubuntu 20.04

First, setup the [Approov CLI](https://approov.io/docs/latest/approov-installation/index.html#initializing-the-approov-cli).

Next, enable your Approov `admin` role with:

```bash
eval `approov role admin`
````

For the Windows powershell:

```bash
set APPROOV_ROLE=admin:___YOUR_APPROOV_ACCOUNT_NAME_HERE___
````

Now, register the API domain for which Approov will issues tokens:

```bash
approov api -keySetKID mule -add api.example.com
```

Next, create the Approov key set that will be used to sign the Approov tokens for your API:

```bash
approov keyset -add RS256 -keyLength 2048 -kid your-api-name
```

Now, get the public key from the Approov keyset configured for your API:

```bash
approov keyset -kid your-api-name -getPEM public-key.pem
```

Next, create one line string for the public key with:

```bash
awk 'NR>2 { sub(/\r/, ""); printf "%s\\n",last} { last=$0 }' public-key.pem > public-key-string.pem
```

Now, apply the Mulesoft policy with:

```bash
anypoint-cli api-mgr policy apply \
    --policyVersion 1.2.0 \
    --config "{\"jwtOrigin\":\"customExpression\", \"jwtKeyOrigin\":\"text\", \"textKey\":\"$(cat public-key-string.pem)\", \"jwtExpression\":\"#[attributes.headers[\\\"Approov-Token\\\"]]\", \"signingMethod\":\"rsa\", \"signingKeyLength\":\"256\", \"jwksUrl\":\"example.com\", \"skipClientIdValidation\":true, \"clientIdExpression\":\"#[vars.claimSet.client_id]\", \"validateAudClaim\":false, \"mandatoryAudClaim\":false, \"supportedAudiences\":\"aud.example.com\",  \"mandatoryExpClaim\":true, \"mandatoryNbfClaim\":false, \"validateCustomClaim\":false}" \
    ___YOUR_API_INSTANCE_ID___ jwt-validation
```
> **NOTE:** Some of the config keys have placeholder values because they are required to be presented when applying the policy, but aren't used at runtime.

Not enough details in the bare bones quickstart? No worries, check the [detailed quickstart](docs/APPROOV_TOKEN_QUICKSTART.md) that contain a more comprehensive set of instructions, including how to test the Approov integration.


## More Information

* [Approov Overview](OVERVIEW.md)
* [Detailed Quickstart](docs/APPROOV_TOKEN_QUICKSTART.md)
* [Step by Step Example](docs/MULESOFT_API_GATEWAY_EXAMPLE.md)
* [Testing](docs/APPROOV_TOKEN_QUICKSTART.md#test-your-approov-integration)


## Issues

If you find any issue while following our instructions then just report it [here](https://github.com/approov/quickstart-mulesoft-api-gateway/issues), with the steps to reproduce it, and we will sort it out and/or guide you to the correct path.


## Useful Links

If you wish to explore the Approov solution in more depth, then why not try one of the following links as a jumping off point:

* [Approov Free Trial](https://approov.io/signup)(no credit card needed)
* [Approov Get Started](https://approov.io/product/demo)
* [Approov QuickStarts](https://approov.io/docs/latest/approov-integration-examples/)
* [Approov Docs](https://approov.io/docs)
* [Approov Blog](https://approov.io/blog/)
* [Approov Resources](https://approov.io/resource/)
* [Approov Customer Stories](https://approov.io/customer)
* [Approov Support](https://approov.io/contact)
* [About Us](https://approov.io/company)
* [Contact Us](https://approov.io/contact)
