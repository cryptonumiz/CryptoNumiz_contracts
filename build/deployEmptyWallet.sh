function get_pubkey {
    echo $(cat ./giver/giver.keys.json | grep "public\": " | cut -d "\"" -f 4)
}

echo GET GIVER PUBKEY
PUBKEY=$(get_pubkey)

echo DEPLOY EMPTY WALLET
tonos-cli --url http://127.0.0.1 call $1 deployEmptyWallet '{"pubkey":"0x'$PUBKEY'","grams":"2000000000"}' --sign RootTokenContractNF.keys.json --abi RootTokenContractNF.abi.json