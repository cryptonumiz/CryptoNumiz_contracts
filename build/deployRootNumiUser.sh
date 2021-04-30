#!/bin/bash
set -e

CONTRACT_NAME=RootNumiUser
giver=0:b5e9240fc2d2f1ff8cbb1d1dee7fb7cae155e5f6320e585fcc685698994a19a5
function giver {
    tonos-cli --url $NETWORK call $giver sendTransaction '{"dest":"'$1'","value":10000000000,"bounce":false}' --abi ./giver/giver.abi.json --sign ./giver/giver.keys.json  
}

function get_address {
    echo $(cat NumiUserRoot.log | grep "Raw address:" | cut -d ' ' -f 3)
}

function genaddr {
    tonos-cli genaddr $1.tvc $1.abi.json --genkey $1.keys.json > NumiUserRoot.log
}

function gen_user_code {
    tvm_linker decode --tvc NumiUser.tvc > code.txt
}

function get_user_code {
    echo $(cat code.txt | grep "code: " | cut -d ' ' -f 3)
}

function get_pubkey {
    echo $(cat $CONTRACT_NAME.keys.json | grep "public\": " | cut -d "\"" -f 4)
}

function deploy_root {
    tonos-cli --url $NETWORK deploy $CONTRACT_NAME.tvc '{"root_public_key":"0x'$TVM_ROOT_PUBKEY'","user_code":"'$TVM_USER_CODE'"}' --abi $CONTRACT_NAME.abi.json --sign $CONTRACT_NAME.keys.json
}

LOCALNET=http://127.0.0.1
DEVNET=https://net.ton.dev
MAINNET=https://main.ton.dev

NETWORK=$LOCALNET

echo GENADDR CONTRACT
genaddr $CONTRACT_NAME
CONTRACT_ADDRESS=$(get_address)

echo ASK GIVER
giver $CONTRACT_ADDRESS

echo GEN USER CODE
gen_user_code

echo GET USER CODE AND PUBKEY
TVM_USER_CODE=$(get_user_code)
TVM_ROOT_PUBKEY=$(get_pubkey)

echo DEPLOY CONTRACT $CONTRACT_ADDRESS
deploy_root

echo DONE
echo $CONTRACT_ADDRESS