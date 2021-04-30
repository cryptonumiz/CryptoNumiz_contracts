#!/bin/bash
set -e

DEBOT_NAME=NumiDebot
giver=0:b5e9240fc2d2f1ff8cbb1d1dee7fb7cae155e5f6320e585fcc685698994a19a5
function giver {
tonos-cli --url $NETWORK call $giver sendTransaction '{"dest":"'$1'","value":10000000000,"bounce":false}' --abi ./giver/giver.abi.json --sign ./giver/giver.keys.json  
}
function get_address {
echo $(cat debot.log | grep "Raw address:" | cut -d ' ' -f 3)
}
function genaddr {
tonos-cli genaddr $1.tvc $1.abi.json --genkey $1.keys.json > debot.log
}

LOCALNET=http://127.0.0.1
DEVNET=https://net.ton.dev
MAINNET=https://main.ton.dev
NETWORK=$LOCALNET

echo GENADDR DEBOT
genaddr $DEBOT_NAME

DEBOT_ADDRESS=$(get_address)
echo $DEBOT_ADDRESS

echo ASK GIVER
giver $DEBOT_ADDRESS
DEBOT_ABI=$(cat $DEBOT_NAME.abi.json | xxd -ps -c 20000)

echo DEPLOY DEBOT $DEBOT_ADDRESS
tonos-cli --url $NETWORK deploy $DEBOT_NAME.tvc "{}" --sign $DEBOT_NAME.keys.json --abi $DEBOT_NAME.abi.json
tonos-cli --url $NETWORK call $DEBOT_ADDRESS setABI "{\"dabi\":\"$DEBOT_ABI\"}" --sign $DEBOT_NAME.keys.json --abi $DEBOT_NAME.abi.json

echo DONE
echo $DEBOT_ADDRESS