// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {Authority} from "@solmate/auth/Auth.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {IWETH} from "src/interfaces/IWETH.sol";
import {IGLPAdapter, AccountState} from "src/interfaces/IGLPAdapter.sol";

import {PrizePoolDistributor} from "src/PrizePoolDistributor.sol";

contract testPrizePoolDistributor is Test {

    uint256 id1 = 6163;
    uint256 id2 = 94;
    uint256 id3 = 112;
    uint256 id4 = 158;

    address owner;
    address trader = makeAddr("trader");
    address keeper = makeAddr("keeper");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address yossi = makeAddr("yossi");
    address muxContainer = address(0xCD4cC991E6cCB8A0Ebfb8f11E68bD5A125D2BB3B);
    address muxContainerOwner;
    address gbcWhale = address(0x5C1E6bA712e9FC3399Ee7d5824B6Ec68A0363C02);
    address gbc = address(0x17f4BAa9D35Ee54fFbCb2608e20786473c7aa49f);

    address private constant WETH = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

    PrizePoolDistributor prizePoolDistributor;

    function setUp() public {

        string memory ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");
        uint256 arbitrumFork = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbitrumFork);

        vm.deal(owner, 100 ether);
        vm.deal(trader, 100 ether);
        vm.deal(keeper, 100 ether);
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(yossi, 100 ether);

        muxContainerOwner = IGLPAdapter(muxContainer).muxAccountState().account;

        vm.startPrank(gbcWhale);
        IERC721(gbc).transferFrom(gbcWhale, alice, id1);
        IERC721(gbc).transferFrom(gbcWhale, alice, id4);
        IERC721(gbc).transferFrom(gbcWhale, bob, id2);
        IERC721(gbc).transferFrom(gbcWhale, muxContainerOwner, id3);
        vm.stopPrank();

        owner = address(0xDe2DBb7f1C893Cc5E2f51CbFd2A73C8a016183a0); // https://arbiscan.io/address/0x575F40E8422EfA696108dAFD12cD8d6366982416#readContract
        IERC721 _gbc = IERC721(gbc);
        Authority _authority = Authority(0x575F40E8422EfA696108dAFD12cD8d6366982416);

        prizePoolDistributor = new PrizePoolDistributor(_authority, _gbc, owner);
    }

    // ============================================================================================
    // Public Functions
    // ============================================================================================

    function testFlow() public {
        (uint256 _aliceReward, uint256 _bobReward, uint256 _yossiReward, uint256 _muxContainerReward) = _testDistribute();
        _testClaim(_aliceReward, _bobReward);
        _testMuxClaim(_muxContainerReward);
        assertEq(IERC20(WETH).balanceOf(address(prizePoolDistributor)), _yossiReward, "testFlow: E0");
        _testDistribute();
    }

    // ============================================================================================
    // Internal Functions
    // ============================================================================================

    function _testDistribute() internal returns (uint256 _aliceReward, uint256 _bobReward, uint256 _yossiReward, uint256 _muxContainerReward) {
        uint256 _oldWETHBalance = IERC20(WETH).balanceOf(address(prizePoolDistributor));
        uint256 _totalNewRewards = 10 ether;

        _aliceReward = 1 ether;
        _bobReward = 2 ether;
        _yossiReward = 3 ether;
        _muxContainerReward = 4 ether;
        uint256[] memory _rewardsList = new uint256[](4);
        _rewardsList[0] = _aliceReward;
        _rewardsList[1] = _bobReward;
        _rewardsList[2] = _yossiReward;
        _rewardsList[3] = _muxContainerReward;

        address[] memory _winnersList = new address[](4);
        _winnersList[0] = alice;
        _winnersList[1] = bob;
        _winnersList[2] = yossi;
        _winnersList[3] = muxContainer;

        address[] memory _faultyWinnersList = new address[](2);
        _faultyWinnersList[0] = alice;
        _faultyWinnersList[1] = bob;

        vm.expectRevert(); // reverts with "UNAUTHORIZED"
        prizePoolDistributor.distribute(6 ether, _rewardsList, _winnersList);

        vm.startPrank(owner);

        vm.expectRevert(); // reverts with "LengthMismatch"
        prizePoolDistributor.distribute(6 ether, _rewardsList, _faultyWinnersList);

        IWETH(WETH).deposit{value: _totalNewRewards}();
        IERC20(WETH).approve(address(prizePoolDistributor), _totalNewRewards);
        prizePoolDistributor.distribute(_totalNewRewards, _rewardsList, _winnersList);
        vm.stopPrank();

        assertEq(prizePoolDistributor.usedTokens(id1), false, "_testDistribute: E0");
        assertEq(prizePoolDistributor.usedTokens(id2), false, "_testDistribute: E1");
        assertEq(prizePoolDistributor.usedTokens(id3), false, "_testDistribute: E2");
        assertEq(prizePoolDistributor.getWinnerReward(alice), 1 ether, "_testDistribute: E3");
        assertEq(prizePoolDistributor.getWinnerReward(bob), 2 ether, "_testDistribute: E4");
        assertEq(prizePoolDistributor.getWinnerReward(yossi), 3 ether, "_testDistribute: E5");
        assertEq(prizePoolDistributor.getWinnerReward(muxContainer), 4 ether, "_testDistribute: E6");
        assertEq(prizePoolDistributor.muxContainerOwner(muxContainer), muxContainerOwner, "_testDistribute: E7");
        assertEq(IERC20(WETH).balanceOf(address(prizePoolDistributor)), _totalNewRewards + _oldWETHBalance, "_testDistribute: E8");
    }

    function _testClaim(uint256 _aliceReward, uint256 _bobReward) internal {
        uint256 _aliceBalanceBefore = IERC20(WETH).balanceOf(alice);
        uint256 _bobBalanceBefore = IERC20(WETH).balanceOf(bob);

        vm.expectRevert(); // reverts with "NotClaimable"
        prizePoolDistributor.claim(5, alice);

        vm.startPrank(owner);
        prizePoolDistributor.setClaimable(true);
        vm.stopPrank();
        
        assertEq(prizePoolDistributor.usedTokens(id1), false, "_testClaim: E00");
        vm.startPrank(alice);
        vm.expectRevert(); // reverts with "NotOwnerOfToken"
        prizePoolDistributor.claim(5, alice);

        uint256 _aliceRewardOut = prizePoolDistributor.claim(id1, alice);

        vm.expectRevert(); // reverts with "TokenAlreadyUsed"
        prizePoolDistributor.claim(id1, alice);

        vm.expectRevert(); // reverts with "AlreadyClaimed"
        prizePoolDistributor.claim(id4, alice);
        vm.stopPrank();

        assertEq(_aliceReward, _aliceRewardOut, "_testClaim: E0");
        assertEq(IERC20(WETH).balanceOf(alice), _aliceBalanceBefore + _aliceReward, "_testClaim: E1");
        assertEq(prizePoolDistributor.usedTokens(id1), true, "_testClaim: E01");
        assertEq(prizePoolDistributor.usedTokens(0), false, "_testClaim: E001");

        assertEq(prizePoolDistributor.usedTokens(id2), false, "_testClaim: E02");
        vm.startPrank(bob);
        uint256 _bobRewardOut = prizePoolDistributor.claim(id2, bob);
        vm.stopPrank();

        assertEq(_bobReward, _bobRewardOut, "_testClaim: E2");
        assertEq(IERC20(WETH).balanceOf(bob), _bobBalanceBefore + _bobReward, "_testClaim: E3");
        assertEq(prizePoolDistributor.usedTokens(id2), true, "_testClaim: E03");
        assertEq(prizePoolDistributor.usedTokens(1), false, "_testClaim: E003");

        assertEq(prizePoolDistributor.usedTokens(id3), false, "_testClaim: E04");
        vm.startPrank(yossi);
        vm.expectRevert(); // reverts with "NotOwnerOfToken"
        prizePoolDistributor.claim(id3, yossi);
        vm.stopPrank();
    }

    function _testMuxClaim(uint256 _muxContainerReward) internal {
        uint256 _muxContainerOwnerBalanceBefore = IERC20(WETH).balanceOf(muxContainerOwner);

        vm.startPrank(owner);
        vm.expectRevert(); // reverts with "NotContainerOwner"
        prizePoolDistributor.muxClaim(id3, muxContainer, muxContainerOwner);
        vm.stopPrank();

        assertEq(prizePoolDistributor.usedTokens(id3), false, "_testClaim: E00");
        vm.startPrank(muxContainerOwner);
        uint256 _muxContainerOwnerRewardOut = prizePoolDistributor.muxClaim(id3, muxContainer, muxContainerOwner);
        vm.stopPrank();

        assertEq(_muxContainerReward, _muxContainerOwnerRewardOut, "_testClaim: E0");
        assertEq(IERC20(WETH).balanceOf(muxContainerOwner), _muxContainerOwnerBalanceBefore + _muxContainerReward, "_testClaim: E1");
        assertEq(prizePoolDistributor.usedTokens(id3), true, "_testClaim: E01");
        assertEq(prizePoolDistributor.usedTokens(2), false, "_testClaim: E001");
    }
}