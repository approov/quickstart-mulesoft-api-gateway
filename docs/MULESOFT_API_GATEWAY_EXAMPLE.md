# MULESOFT API GATEWAY EXAMPLE

This example is for developers not familiar with Mulesoft API Gateway who are looking for a step by step tutorial on how they can create an API project with an [Approov](https://approov.io) token check.

By following this example you will create an API that will act as a [Reverse Proxy](https://approov.io/blog//using-a-reverse-proxy-to-protect-third-party-apis) to an unprotected API. The proxy will only forward requests made by your mobile app.

The reverse proxy with an Approov token check that is built here can also be used in other circumstances where the target of a request needs to be protected from bots, scripts, or other malicious accesses. For example, the target could be another backend, managed by you or someone else. The Approov integration steps will be the same no matter what type of backend the reverse proxy is configured to access.


## TOC - Table of Contents

* [Why?](#why)
* [How it Works?](#how-it-works)
* [Requirements](#requirements)
* [How to Follow the Instructions?](#how-to-follow-the-instructions)
* [Setup](#setup)
* [Mulesoft Api Gateway](#mulesoft-api-gateway)
* [Approov Token Check](#approov-token-check)
* [Test your Approov Integration](#test-your-approov-integration)
* [Troubleshooting](#troubleshooting)


## Why?

To lock down your API server to your mobile app. Please read the brief summary in the [Approov Overview](/OVERVIEW.md#why) at the root of this repo or visit our [website](https://approov.io/product) for more details.

[TOC](#toc---table-of-contents)


## How it works?

For more background, see the [Approov Overview](/OVERVIEW.md#how-it-works) at the root of this repo.

[TOC](#toc---table-of-contents)


## Requirements

To complete this quickstart example you will need to have de following installed:

* [Mulesoft Anypoint CLI](https://docs.mulesoft.com/runtime-manager/anypoint-platform-cli) - Will be used to create all the necessary resources in the Mulesoft platform.
* [Approov CLI](https://approov.io/docs/latest/approov-installation/#approov-tool) - Will be used to setup your Approov secrets and to configure the API you want to protect.
* [Docker CLI](https://docs.docker.com/get-docker/) (optional) - Will be used to run the the anypoint-cli.

This guide was tested with the following Operating Systems:

* Ubuntu 20.04
* MacOS Big Sur
* Windows 10 WSL2 - Ubuntu 20.04

[TOC](#toc---table-of-contents)


## How to Follow the Instructions

When following the instructions you have the option to do it using a helper bash script, `./stack`, or you can enter the individual commands for `docker`, `anypoint` and `approov` CLIs by hand.


An example for the helper script, `./stack`:

```bash
./stack api-deploy
```

The example for the correspondent `anypoint-cli` command:

```bash
anypoint-cli api-mgr api deploy \
  --gatewayVersion 4.4.0 \
  --applicationName ${MULESOFT_APPLICATION_NAME} \
  ${API_INSTANCE_ID}
```

> **NOTE:** The required variables (${VARIABLE_NAME}) in the above command are defined in the `.env` file and others will be exported to the environment as we go through the instructions. For example the value for the `${API_INSTANCE_ID}` can only be known after we create the API, so it is not in the `.env` file, but you will see an instruction to export at the appropriate point.

Choose the one you feel more comfortable with, you will get the same outcome either way.


[TOC](#toc---table-of-contents)


## Setup

### Clone this Repo

Command:

```text
git clone https://github.com/approov/quickstart-mulesoft-api-gateway.git
cd quickstart-mulesoft-api-gateway
```

### Setup the Environment Variables

During this quickstart we will reuse some values several times when invoking the Anypoint or Approov CLI, therefore we will configure them in a `.env` file and then export them to the environment.

#### Prepare the Env File

The `.env.example` file contains the initial set of variables that you need to export to the environment.

Copy the `.env.example` to `.env` with:

```bash
cp .env.example .env
```

Next, customize the `.env` file for your setup by following the instructions in the comments for each env var.

Now, export all the env vars on the `.env` file to the environment with the following command:

```bash
export $(grep -v '^#' .env | xargs -0)
```

### The Third Party API Setup

To demonstrate Approov protection of a third party API using the Mulesoft API Gateway as a reverse proxy, we need an API to protect, and for this quickstart example we will use `https://httpbin.org` to simulate an unprotected API that we want to restrict access to. You can continue by using an unprotected API of your choice.

### Approov CLI Setup

#### Approov CLI Installation

Follow the [Approov CLI](https://approov.io/docs/latest/approov-installation/#approov-tool) installation instructions in our docs, and if you don't have yet an Approov account then you can start an [Approov trial](https://www.approov.io/signup/), that doesn't require a credit card or any other billing information.

#### Approov CLI Role

To use the Appoov CLI in the next steps you need to enable the role under which you will run the commands. While the `approov api` command can be executed with the basic `dev` role, other commands will require an `admin` role, see [account access roles documentation](https://approov.io/docs/latest/approov-usage-documentation/#account-access-roles).

Enable your Approov `admin` role with:

```bash
eval `approov role admin`
```
> **NOTE:** First time that you will execute an Approov command you will be prompted for your password, authenticate your selected Approov role with your password. This will create an authenticated session that will expire in 1 hour, after which you will again be prompted for your password.

### Anypoint CLI Setup

Feel free to use your installed `anypoint-cli`, instead of the dockerized `3.9.1` version used in this quickstart. If you run into issues due to your `anypoint-cli` being of a different version, then prefix any use of `anypoint-cli` with the `./stack` bash script helper. For example `./stack anypoint-cli`, will run the `anypont-cli` version `3.9.1` on a docker container. To build the docker container run first `./stack build-docker`.

If you don't have a Mulesoft account yet, then you need to [signup](https://anypoint.mulesoft.com/login/signup) for one in order to be able to use the Anypoint CLI.

[TOC](#toc---table-of-contents)


## Mulesoft API Gateway

We will use the Mulesoft API Gateway as a reverse proxy for a third party API, that later we will integrate Approov on to only accept requests containing a valid Approov token.

### Create the API in Mulesoft

The Mulesoft API we are about to create will use HTTP instead of HTTPS, and this is because we are not aware of how to use LetsEncrypt with the Mulesoft API Gateway to auto-generated a certificate for deploying into the Mulesoft Sandbox environment at `<application-name>.us-e2.cloudhub.io`. For a production project always use HTTPS as instructed in the note below the `anypoint-cli api-mgr api manage` command.

To create the API execute one of the commands:

```bash
./stack api-create ${MULESOFT_API_BACKEND_URL} ${MULESOFT_EXCHANGE_ASSET_ID} 1.0.0
```

or

```bash
anypoint-cli api-mgr api manage \
    --type http \
    --withProxy true \
    --muleVersion4OrAbove true \
    --deploymentType cloudhub \
    --uri ${MULESOFT_API_BACKEND_URL} \
    --scheme http \
    --port 8081 \
    --path / \
    ${MULESOFT_EXCHANGE_ASSET_ID} 1.0.0
```

> **IMPORTANT:**
>
> On a production API use instead:
> * `--scheme https`
> * `--port 443`

Output:

```text
Created new API with ID: 12345678
```

Now, from the output of the command grab the API Instance ID, for example `12345678`, and export it to the environment:

```bash
# Replace 12345678 with your value
export API_INSTANCE_ID=12345678
```

### Deploy the API

Execute one of the commands:

```bash
./stack api-deploy ${MULESOFT_APPLICATION_NAME} ${API_INSTANCE_ID}
```

or

```bash
anypoint-cli api-mgr api deploy \
  --gatewayVersion 4.4.0 \
  --applicationName ${MULESOFT_APPLICATION_NAME} \
  ${API_INSTANCE_ID}
```

[TOC](#toc---table-of-contents)


## Approov Token Check

Approov tokens are standard JSON Web Tokens(JWTs), thus to check it in any existing Mulesoft API Gateway project you just need to apply the JWT policy with the Approov public key from the certificate used to sign the JWT.


To use Approov with Mulesoft API Gateway you need a small amount of configuration. First, Approov needs to know the API domain that will be protected. Second, Mulesoft API Gateway needs to know the public key to use in order to verify the JWT tokens generated by the Approov cloud service.


### Approoov Keyset

To sign the Approov token a privat/public key pair will be used and auto generated by the Approov service.

Let's create one with:

```bash
# approov keyset -add RS256 -keyLength 2048 -kid mule
approov keyset -add RS256 -keyLength 2048 -kid ${APPROOV_KEYSET_ID}
```

> **NOTE:** The `-kid` is optional and if not provided an incremental numeric ID will be used.


### Configure API Domain

Approov needs to know the domain name of the API for which it will issue tokens.

Add the Mulesoft API domain with:

```bash
# approov api -keySetKID mule -add shapes.us-e2.cloudhub.io
approov api -keySetKID ${APPROOV_KEYSET_ID} -add ${MULESOFT_API_DOMAIN}
```

Adding the API domain also configures [dynamic certificate pinning](https://approov.io/docs/latest/approov-usage-documentation/#approov-dynamic-pinning) for the API, the apps using your API need to be modified to take advantage of this.

> **NOTE:** By default the pin is extracted from the public key of the leaf certificate served by the domain, as visible to both the box issuing the Approov CLI command and the Approov servers. Other `approov` commands can modify this default.

### Apply the Mulesoft JWT Policy to the API

First, get the public key from the Approov keyset configured for your API:

```bash
# approov keyset -kid mule -getPEM public-key.pem
approov keyset -kid ${APPROOV_KEYSET_ID} -getPEM public-key.pem
```

Next, create one line string for the public key with:

```bash
awk 'NR>2 { sub(/\r/, ""); printf "%s\\n",last} { last=$0 }' public-key.pem > public-key-string.pem
```

> **NOTE:** - Removes the first and last line from the certificate and preserves new lines with `\n` to allow to use the certificate as 1 line string in the JSON we need to pass in the `--config` parameter.

Now, apply the policy with:

```bash
./stack policy-jwt-apply ${API_INSTANCE_ID}
````

or with:

```bash
anypoint-cli api-mgr policy apply \
    --policyVersion 1.2.0 \
    --config "{\"jwtOrigin\":\"customExpression\", \"jwtKeyOrigin\":\"text\", \"textKey\":\"$(cat public-key-string.pem)\", \"jwtExpression\":\"#[attributes.headers[\\\"Approov-Token\\\"]]\", \"signingMethod\":\"rsa\", \"signingKeyLength\":\"256\", \"jwksUrl\":\"example.com\", \"skipClientIdValidation\":true, \"clientIdExpression\":\"#[vars.claimSet.client_id]\", \"validateAudClaim\":false, \"mandatoryAudClaim\":false, \"supportedAudiences\":\"aud.example.com\",  \"mandatoryExpClaim\":true, \"mandatoryNbfClaim\":false, \"validateCustomClaim\":false}" \
    ${API_INSTANCE_ID} jwt-validation
```
> **NOTE:** Some of the config keys have placeholder values because they are required to be presented when applying the policy, but aren't used at runtime.

The Mulesoft platform may take more then one minute to effectively apply the policy to your API, therefore wait for one minute or two before you proceed to the next step of testing your Approov integration.

[TOC](#toc---table-of-contents)


## Test your Approov Integration

The examples below use cURL to perform a request adding valid, invalid and no Approov token. You will need to expand these requests to include all the properties expected by the protected API. If you have an existing test setup using Postman, or some other mechanism/tool, then it should be easy to adjust that to add the different tests listed here.

### With Invalid Approov Tokens

Make a cURL request using one of the routes to which you added the Approov authorizer:

```bash
curl -iX GET "http://${MULESOFT_API_DOMAIN}" \
  --header "Approov-Token: $(approov token -type invalid -genExample ${MULESOFT_API_DOMAIN})"
```

> **NOTE**: If this command fails to complete, then it's probably because your Approov CLI authenticated session has expired and it is waiting for your password input. Kill the command and authenticate again as instructed in the Troubleshooting [section](#approov-cli-authentication-expired).

The above request should fail with an Unauthorized error. For example:

```json
{
  "error": "Invalid token."
}
```

> **NOTE:** If you see a `200` response instead of the expected `401` then it means that the Mulesoft API has not finished to apply the JWT policy for checking the Approov token, therefore you need to retry again in a few seconds, otherwise you may have failed to properly follow some of the previous steps.

### Without the Required Approov Token Header

Make a cURL request using one of the routes to which you added the Approov authorizer:

```bash
curl -iX GET "https://${MULESOFT_API_DOMAIN}"
```

Output:

```json
{
  "error": "JWT Token is required."
}
```

### With Valid Approov Tokens

Make a cURL request using one of the routes to which you added the Approov authorizer:

```bash
curl -iX POST "http://${MULESOFT_API_DOMAIN}/anything" \
  --header "Approov-Token: $(approov token -type valid -genExample ${MULESOFT_API_DOMAIN})" \
  --data '{"target": "https://approov.io"}'
```

The result of the cURL request should successful as defined by the protected API.

[TOC](#toc---table-of-contents)


## Troubleshooting

### Approov CLI Authentication Expired

The Approov CLI prompts for a password when the first approov command is issued after selecting an `admin` role and every hour after that. If you execute an Approov CLI command in a sub-shell, then the password prompt and opportunity for input may be lost. If a command sequence fails then it may be because your session has expired. Run a simple Approov CLI command to see if you need to renew your session, most commands will require a password to complete, even if the command just displays a help message::

```bash
approov api
```

Note that `approov role .` can be used to extend an active session. See [approov role](https://approov.io/docs/latest/approov-cli-tool-reference/#role-command) documentation.

[TOC](#toc---table-of-contents)


## Issues

If you find any issue while following our instructions then just report it [here](https://github.com/approov/quickstart-mulesoft-api-gateway/issues), with the steps to reproduce it, and we will sort it out and/or guide you to the correct path.

[TOC](#toc---table-of-contents)


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

[TOC](#toc---table-of-contents)
