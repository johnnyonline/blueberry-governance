// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Authority} from "@solmate/auth/Auth.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {PrizePoolDistributor} from "src/PrizePoolDistributor.sol";

import "forge-std/Script.sol";
import "forge-std/console.sol";

contract DeployPrizePoolDistributor is Script {

    function run() public {
        
        uint256 _deployerPrivateKey = vm.envUint("GBC_DEPLOYER_PRIVATE_KEY");
        address _deployer = vm.envAddress("GBC_DEPLOYER_ADDRESS");
        address _owner = address(0xDe2DBb7f1C893Cc5E2f51CbFd2A73C8a016183a0); // https://arbiscan.io/address/0x575F40E8422EfA696108dAFD12cD8d6366982416#readContract
        IERC721 _gbc = IERC721(0x17f4BAa9D35Ee54fFbCb2608e20786473c7aa49f);
        Authority _authority = Authority(0x575F40E8422EfA696108dAFD12cD8d6366982416);

        vm.startBroadcast(_deployerPrivateKey);

        PrizePoolDistributor _prizePoolDistributor = new PrizePoolDistributor(_authority, _gbc, _owner);

        console.log("============================================================");
        console.log("============================================================");
        console.log("_prizePoolDistributor: ", address(_prizePoolDistributor));
        console.log("============================================================");
        console.log("============================================================");

        vm.stopBroadcast();
    }
}

// ---- Notes ----

// deployed at `0xEF4E37D97D24a3E8fbD608A0b1a45380E21d1C3a`

// forge script script/DeployPrizePoolDistributor.s.sol:DeployPrizePoolDistributor --rpc-url $RPC_URL --broadcast
// https://abi.hashex.org/ - for constructor
// forge verify-contract --watch --chain-id 42161 --compiler-version v0.8.17+commit.8df45f5f --verifier-url https://api.arbiscan.io/api 0xB900A00418bbD1A1b7e1b00A960A22EA540918a2 src/shared/lending/FortressLendingPair.sol:FortressLendingPair
// --constructor-args 000000000000000000000000575f40e8422efa696108dafd12cd8d636698241600000000000000000000000017f4baa9d35ee54ffbcb2608e20786473c7aa49f000000000000000000000000de2dbb7f1c893cc5e2f51cbfd2a73c8a016183a0