#!/bin/bash
set -e

CONTRACT_NAME=RootTokenContractNF
giver=0:b5e9240fc2d2f1ff8cbb1d1dee7fb7cae155e5f6320e585fcc685698994a19a5

LOCALNET=http://127.0.0.1
DEVNET=https://net.ton.dev
MAINNET=https://main.ton.dev

NETWORK=$LOCALNET

function giver {
    tonos-cli --url $NETWORK call $giver sendTransaction '{"dest":"'$1'","value":100000000000,"bounce":false}' --abi ./giver/giver.abi.json --sign ./giver/giver.keys.json  
}

function get_address {
    echo $(cat $CONTRACT_NAME.log | grep "Raw address:" | cut -d ' ' -f 3)
}

function genaddr {
    tonos-cli genaddr $1.tvc $1.abi.json --genkey $1.keys.json > $CONTRACT_NAME.log
}

function gen_wallet_code {
    tvm_linker decode --tvc TONTokenWalletNF.tvc > code.txt
}

function get_wallet_code {
    echo $(cat code.txt | grep "code: " | cut -d ' ' -f 3)
}

function get_pubkey {
    echo $(cat $CONTRACT_NAME.keys.json | grep "public\": " | cut -d "\"" -f 4)
}

function deploy_root {
    tonos-cli --url $NETWORK deploy $CONTRACT_NAME.tvc '{"name":"54657374","symbol":"545354","decimals":"0","front_side_image":"68747470733a2f2f736974652e696f2f696d672e6a7067","back_side_media":"68747470733a2f2f736974652e696f2f6d656469612e6d7034","curator":"0:0000000000000000000000000000000000000000000000000000000000000000","creator":"0:0000000000000000000000000000000000000000000000000000000000000001","creator_percent":"5","numi_event":"0:0000000000000000000000000000000000000000000000000000000000000002","root_public_key":"0x'$TVM_ROOT_PUBKEY'","wallet_code":"'$TVM_WALLET_CODE'"}' --abi $CONTRACT_NAME.abi.json --sign $CONTRACT_NAME.keys.json
}

echo GENADDR CONTRACT
genaddr $CONTRACT_NAME
CONTRACT_ADDRESS=$(get_address)

echo ASK GIVER
giver $CONTRACT_ADDRESS

echo GEN WALLET CODE
gen_wallet_code

echo GET WALLET CODE AND PUBKEY
TVM_WALLET_CODE=$(get_wallet_code)
TVM_ROOT_PUBKEY=$(get_pubkey)

echo DEPLOY ROOT TOKEN CONTRACT
deploy_root