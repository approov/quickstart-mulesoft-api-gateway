#!/bin/bash

set -eu

Show_Help() {
  cat <<EOF

  A bash script wrapper for Docker and ANYPOINT CLI.


  SYNOPSIS:

  $ ./stack <command> <argument>


  COMMANDS:

    api-create            Creates an HTTP API in Mulesoft API Gateway:
                          $ ./stack api-create <API_BACKEND> <EXCHANGE_ASSET_ID> <VERSION>
                          $ ./stack api-create https://httpbin.org approov-reverse-proxy-example 1.0.0

    api-deploy            Deploys the HTTP API to CLoudHub:
                          $ ./stack api-deploy <APPLICATION_NAME> <API_INSTANCE_ID>
                          $ ./stack api-deploy httpbin 1234567

    build-docker          Builds the docker image for the Anypoint CLI
                          $ ./stack build-docker

    info-account          Retrieves account info for the configured Mulesoft user:
                          $ ./stack info-account

    info-assets           Retrieves info about all assets:
                          $ ./stack info-assets

    info-organization-id  Retrieves the user organization ID:
                          $ ./stack info-organization-id

    oauth-token           Logins the user via OAUTH:
                          $ ./stack oauth-token

    policy-jwt-apply      Enables verification of the Approov Token via a JWT Policy:
                          $ ./stack policy-jwt-apply <API_INSTANCE_ID>
                          $ ./stack policy-jwt-apply 1234567

    shell                 Runs docker container with a bash shell
                          $ ./stacl shell

EOF
}

# Some of the functionality exposed in this bash helper script is not available
# through the anypoint-cli, and was inspired in this help article:
# @link https://help.mulesoft.com/s/article/How-to-get-asset-information-from-Exchange-using-Exchange-Experience-API

Mulesoft_Auth_Token() {
  local _token=$(curl -s https://anypoint.mulesoft.com/accounts/login \
    --data "username=${MULESOFT_USERNAME}&password=${MULESOFT_PASSWORD}" \ |
    grep -i 'access_token' | awk '{print $2}' | tr -d '",')

  echo "${_token}"
}

Mulesoft_Oauth_Token() {
  echo "MULESOFT_AUTHORIZATION_TOKEN=$(Mulesoft_Auth_Token)" >> .env

  echo "Added to the .env file:"
  cat .env | grep MULESOFT_AUTHORIZATION_TOKEN -
}

Mulesoft_Account_Info() {
  curl -s https://anypoint.mulesoft.com/accounts/api/me \
    --header "Authorization: Bearer $(Mulesoft_Auth_Token)" \
    --header "Content-Type: application/json"
}

Mulesoft_Assets_Info() {
  curl -s "https://anypoint.mulesoft.com/exchange/api/v1/assets?type=rest-api&organizationId=$(Mulesoft_Organization_Id)" \
    --header "Authorization: bearer $(Mulesoft_Auth_Token)" \
    --header "Content-Type: application/json" | python -m json.tool
}


Mulesoft_Organization_Id() {
  Mulesoft_Account_Info | grep -i '"organizationId":' | awk '{print $2}' | tr -d '",'
}

Mulesoft_API_Create() {
    # --serviceName "${1? Missing service name, eg. myservice}" \
  Docker_Run anypoint-cli api-mgr api manage \
    --type http \
    --withProxy true \
    --muleVersion4OrAbove true \
    --deploymentType cloudhub \
    --uri ${1? Missing API Implementation URL, eg. https://your.api-backend.com} \
    --scheme http \
    --port 8081 \
    --path / \
    "${2? Missing the assetId from Mulesoft Exchange, eg. myasset}" ${3? Missing API version, eg. 1.0.0}
}

Mulesoft_Policy_Json_config() {
  # Removes the first and last line from the certificate and preserves new lines
  # with `\n` to allow to use the certificate as 1 line string in the JSON we need
  # to pass in the `--config` parameter.
  local _public_key="$(awk 'NR>2 { sub(/\r/, ""); printf "%s\\n",last} { last=$0 }' public-key.pem)"

  # some keys have placeholder values because they are required to be presented
  # when applying the policy, but aren't used at runtime.
  local _config="{\"jwtOrigin\":\"customExpression\", \"jwtKeyOrigin\":\"text\", \"textKey\":\"${_public_key}\", \"jwtExpression\":\"#[attributes.headers[\\\"Approov-Token\\\"]]\", \"signingMethod\":\"rsa\", \"signingKeyLength\":\"256\", \"jwksUrl\":\"example.com\", \"skipClientIdValidation\":true, \"clientIdExpression\":\"#[vars.claimSet.client_id]\", \"validateAudClaim\":false, \"mandatoryAudClaim\":false, \"supportedAudiences\":\"aud.example.com\",  \"mandatoryExpClaim\":true, \"mandatoryNbfClaim\":false, \"validateCustomClaim\":false}"

  echo "${_config}"
}

Mulesoft_Policy_JWT_Apply() {

  if [ ! -f public-key.pem ]; then
    printf "\n---> Missing file public-key.pem. Retrieve it with:\n"
    printf "\napproov keyset -kid mule -getPEM public-key.pem\n\n"
    exit 1
  fi

  # Policy applied. New policy ID: "2380477"
  Docker_Run anypoint-cli api-mgr policy apply \
    --policyVersion 1.2.0 \
    --config "$(Mulesoft_Policy_Json_config)" \
    "${1? Missing API instance ID, eg. 1234567}" jwt-validation
}

Mulesoft_API_Deploy() {
  Docker_Run anypoint-cli api-mgr api deploy \
    --gatewayVersion 4.4.0 \
    --applicationName ${1? Missing the the Application name, eg. myapi} \
    ${2? Missing the API instance ID, eg. 1234567}
}

Docker_Run() {
  sudo docker run \
    --rm \
    -it \
    --env "ANYPOINT_ENV=${ANYPOINT_ENV:-Sandbox}" \
    --env "ANYPOINT_USERNAME=${MULESOFT_USERNAME? Missing MULESOFT_USERNAME env var}" \
    --env "ANYPOINT_PASSWORD=${MULESOFT_PASSWORD? Missing MULESOFT_PASSWORD env var}" \
    approov/anypoint-cli "${@}"
}

Main() {

  if [ -f ./.env ]; then
    . ./.env
  fi

  for input in "${@}"; do
    case "${input}" in
      -h | --help )
        Show_Help
        exit $?
        ;;

      anypoint-cli )
        Docker_Run "${@}"
        exit $?
      ;;

      api-create )
        shift 1
        Mulesoft_API_Create "${@}"
        exit $?
      ;;

      api-deploy )
        shift 1
        Mulesoft_API_Deploy "${@}"
        exit $?
      ;;

      build-docker )
        sudo docker build --tag approov/anypoint-cli ./docker
        exit $?
      ;;

      info-assets )
        Mulesoft_Assets_Info
        exit $?
      ;;

      info-account )
        Mulesoft_Account_Info
        exit $?
      ;;

      info-organization-id )
        Mulesoft_Organization_Id
        exit $?
      ;;

      oauth-token )
        Mulesoft_Oauth_Token
        exit $?
      ;;

      policy-jwt-apply )
        shift 1
        Mulesoft_Policy_JWT_Apply "${@}"
        exit $?
      ;;

      shell )
        Docker_Run bash
        exit $?
      ;;

    esac
  done

  Show_Help

}

Main "${@}"
