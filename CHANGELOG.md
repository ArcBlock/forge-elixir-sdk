## 0.33.0 (July 10, 2019)
  - fix gas balance display (#122)
  - Update README.md

## 0.32.2 (July 04, 2019)
  - fix display issue for tx protocol

## 0.32.1 (July 04, 2019)
  - fix display issue

## 0.32.0 (July 04, 2019)
  - support group

## 0.31.1 (July 3, 2019)
  - Support atomic swap.

## 0.31.0 (June 21, 2019)
  - Update deps
  - Update gas when connect to forge
  - Assemble tx with gas
  - Update gas every 1s in RpcConn
  - Tweak on conn supervisor
  - Add gas when ForgeSdk.connect

## 0.30.0 (June 11, 2019)
  - release version 0.30.0
  
## 0.29.1 (June 08, 2019)
  - add bbmustache as dependency.

## 0.29.0 (June 05, 2019)
  - bump version to 0.29.0 to match with forge

## 0.28.3 (May 31, 2019)


## 0.28.2 (May 30, 2019)
  - fix dialyzer
  - support one_token, token_to_unit, unit_to_token for multiple chains
  - add wallet test back
  - move tests back to forge
  - add get_parsed_config
  - support multiple grpc

## 0.27.3 (May 24, 2019)
  - Support listing tethers

## 0.27.2 (May 17, 2019)
  - update deps


## 0.27.1 (May 17, 2019)
  - Correctly handle :chan option.

## 0.27.0 (May 16, 2019)
  - upgrade sdk to 0.27.0 with latest forge-abi

## 0.26.6 (May 13, 2019)
  - Add support for callback function
  - Add connection options for single connection for grpc server
  - handle_info use logger debug

## 0.26.5 (May 10, 2019)
  - support asset address change

## 0.26.4 (May 08, 2019)
  - Support revoke tether transaction.

## 0.26.3 (May 08, 2019)
  - add license

## 0.26.2 (May 07, 2019)
  - Support withdraw and approve tether transaction.

## 0.26.1 (May 07, 2019)
  - update docs (#105)

## 0.26.0 (May 07, 2019)
  - make sdk ready for release
  - add sdk docs (#104)
  - Update readme (#103)
  - alias unit_to_token / token_to_unit in forge sdk
  - fix multisig type display issue (#101)
  - better API for multisig txs (#100)

## 0.25.2 (May 03, 2019)
  - add the tx builder back
  - clean up forge sdk
  - support embedded protocols (#96)
  - Use address to query tether state. (#95)
  - add enabled for forge poke config
  - add default configuration for forge release
  - update deps
  - Support exchange tether tx. (#94)
  - fix sdk loader. Client need the functionalities from Helper
  - load forge transaction configuration correctly
  - update deps
  - add declare config
  - add forge tx configuration
  - support asset factory (#93)
  - uptake forge-abi (#92)
  - update get_tx_protocols parameter (#91)
  - Implement deposit tether transaction. (#87)
  - load rpc helper (#90)
  - support update type url in elixir sdk (#89)
  - deprecate accountMigrate and createAsset in TransactionInfo (#86)
  - deprecate unused protocols (#88)
  - update deps
  - fix typo
  - update dep
  - uptake forge_abi version: remove data_version (#85)
  - support generating tx address (#76)
  - Swaps the arguments for multisig! function. (#84)
  - support upgrade node tx (#83)
  - bug-fix/get_unconfirmed_txs-issue (#82)
  - Apis refactoring batch 2 (#81)
  - deprecate graqhql apis and fields (#80)
  - Use unix domian socket for forge/tendermint connection (#79)
  - Put the encoded protobuf binary value when displaying Any. (#77)
  - remove simlator start/stop from grpc (#78)
  - uptake abi version: add avgBlockTime to stat apis (#75)
  - Always show value when dispalying Google.Protobuf.Any (#74)
  - add geoip config in toml file (#73)
  - Use did type to create asset address (#71)
  - use default consume_time for unconsumed asset (#72)
  - Larger recv buffer for ex_abci server (#70)
  - convert tendermint hash to abt did (#69)
  - Add workshop db path into config. (#68)
  - uptake latest abi version (#67)
  - fix deps
  - fix update_config.
  - add apis to start/stop/get_status simulator (#66)
  - add-get-health-status-api (#65)
  - fix get config api (#64)

## 0.20.0 (March 25, 2019)
  - upgrade forge abi
  - put several params in forge config
  - fix various issues
  - add pk in transaction
  - create tx locally

## 0.19.6 (March 23, 2019)
  - bump forge abi to include ex_abci_proto change

## 0.19.5 (March 22, 2019)
  - list_assets with account and list of assets returns (#59)
  - fix typo
  - restructure paths (#58)
  - add bitmap path (#57)
  - Add port option for forge.web (#56)
  - Uptake new version of forge abi (#55)
  - add indexer url (#52)
  - Uptake new version of DID. (#54)
  - Change use ForgeAbi.Arc to ForgeAbi.Unit (#53)
  - reorganize poke pipe (#48)
  - add checkin (#51)
  - Add sha2. (#49)
  - Fix atom not exist issue when testing on manager app (#50)
  - Add docs for forge_default.toml (#45)
  - Uptake new abt-did-elixir v 0.2.0 (#47)
  - use latest forge-abi
  - use better delimer (#46)
  - uptake to forge_abi version (#44)
  - list_blocks and save block_header to state DB (#43)
  - Change recheck to false for tendermint mempool (#42)
  - improve tx_info data (#41)
  - fix test case
  - use latest forge-abi
  - for compression, default to zstd (#40)
  - use new poke address (#39)
  - uptake abi version (#38)
  - support poke tx (#37)
  - Update forge_abi hash (#36)
  - Add forge token section in forge config toml (#34)
  - CLIENT SIDE BLOCKER.  Encode 'value' field of Google.Protobuf.Any type in its ForgeSdk.display implementation (#35)
  - uptake forge_abi version (#33)
  - do not parse data field for multisig
  - update to latest forge abi
  - Update mcrypto (#32)

## 0.17.0 (March 04, 2019)
  - support consume asset tx
  - Remove forge_starter in toml (#29)
  - add account recent_num_txs && list asset txs (#30)
  - uptake forge_abi version (#28)
  - listTxs with mutal dir and getNodeInfo (#27)
  - support multiple db (#26)
  - update params in tx related apis (#25)

## 0.15.1 (February 23, 2019)
  - add more logs
  - Uptake new version of abt-did-elixir (#20)
  - Use configurable ipfs ports (#18)
  - support activate tx (#23)
  - add empty filter when query blocks (#21)
  - add tx sign doc (#22)
  - update forge_abi version (#19)
  - support index state db related apis (#17)
  - update forge_abi version (#16)

## 0.15.0 (February 18, 2019)
  - tune consensus params (#15)
  - add grpc for signing data with wallet and token (#14)
  - fix forge consensus / storage config issue
  - add more default config
  - fix declare node rpc (#13)

## 0.14.1 (February 15, 2019)
  - add get-asset-address grpc (#12)
  - update forge_abi dep (#11)
  - add list transactions apis (#10)
  - tune max block size to 600k

## 0.14.0 (February 13, 2019)
  - add compression in forge config (#9)
  - impl for serializable (#8)
  - remove put raw (#7)
  - add serializable. (#6)
  - Fix dialyzer warning for file-related api (#5)
  - update circular queue test cases (#4)
  - update forge-abi to latest master
  - improve display protocol (#3)
  - use forge-abi master
  - change max bytes for a block to 1.2m bytes (previous ~20M). (#2)
  - use forge-abi.

## 0.13.3 (February 10, 2019)
  - fix credo issues
  - fix dialyzer
