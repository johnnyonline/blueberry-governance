// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Votes} from "@openzeppelin/contracts/governance/utils/Votes.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract GBCVotes is Votes {

    address GBC = address(0x17f4BAa9D35Ee54fFbCb2608e20786473c7aa49f);
    mapping(address => bool) public whitelist;

    /********************************** Constructor **********************************/

    constructor(address _admin) {
        admin = _admin;
    }

    /********************************** External functions **********************************/

    function updateVotingUnits(address _from, address _to) external {
        if (!whitelist[msg.sender]) revert Unauthorised();

        _transferVotingUnits(_from, _to, 1);

        // TODO: emit event
    }

    function updateWhitelist(address _account, bool _whitelist) external {
        if (msg.sender != admin) revert Unauthorised();

        whitelist[_account] = _whitelist;

        // TODO: emit event
    }

    /********************************** Internal functions **********************************/

    function _getVotingUnits(address account) internal view override returns (uint256) {
        return IERC721(GBC).balanceOf(account);
    }
}