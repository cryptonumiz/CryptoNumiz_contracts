tonos-cli --url http://net.ton.dev call $1 deployUploader '{"chunks_count":"'$2'"}' --abi RootRawUploader.abi.json --sign uploader.keys.json