pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "src/tournament/TournamentRBT.sol";
import "src/NFT/F3NFT.sol";
import "src/F3Token.sol";
import "src/F3Box.sol";
import "src/MockRandom.sol";
import "src/PoolReward.sol";
import "src/BUSDMock.sol";
import "openzeppelin/token/ERC20/ERC20.sol";
import "forge-std/console.sol";
import "src/Referral.sol";

contract TournamentRBTTest is Test {
	TournamentRBT _tournament;
	F3 _f3;
	BUSDMock _usdToken;
	F3NFT _f3NFT;
	F3Box _f3Box;
	PoolReward _poolReward;
	MockRandom _secureRandom;
	LotteryToken _lotteryToken;
	address me = address(10000);
	uint160 totalPlayers = 200;
	uint256 private constant _DURATION = 7200;
	Referral _referral;

	function _getAccount(uint160 i) internal returns (address) {
		return address(i);
	}

	function setUp() public {
		skip(10_000_000);
		_f3 = new F3();
		_f3.grantRole(_f3.MINTER_ROLE(), me);
		_f3NFT = new F3NFT(address(_f3));
		_usdToken = new BUSDMock();
		_poolReward = new PoolReward(address(_usdToken));
		_secureRandom = new MockRandom();
		_referral = new Referral();
		_f3Box = new F3Box(
			address(_usdToken),
			address(_f3NFT),
			address(_secureRandom),
			address(_poolReward),
			address(_f3),
			address(_referral)
		);

		_referral.grantRole(_referral.UPDATE_ROLE(), address(_f3Box));

		_lotteryToken = new LotteryToken();

		_f3.grantRole(_f3.MINTER_ROLE(), address(_f3Box));

		_tournament = new TournamentRBT(
			block.timestamp - _DURATION * 2,
			block.timestamp + _DURATION * 3,
			_DURATION,
			address(_f3),
			address(_f3NFT),
			address(_poolReward),
			address(_lotteryToken),
			address(_secureRandom)
		);

		_lotteryToken.grantRole(_lotteryToken.MINTER_ROLE(), address(_tournament));

		_poolReward.addMember(address(_tournament), 7000);

		_f3NFT.grantRole(_f3NFT.TRANSFER_CENTER_ROLE(), address(_tournament));

		console.log("f3", address(_f3));
		console.log("F3NFT", address(_f3NFT));
		console.log("_poolReward", address(_poolReward));
		console.log("_secureRandom", address(_secureRandom));
		console.log("F3Box", address(_f3Box));
		console.log("_tournament", address(_tournament));

		_f3NFT.grantRole(_f3NFT.MINTER_ROLE(), address(_f3Box));

		for (uint160 i = 1; i <= totalPlayers; i++) {
			address account = _getAccount(i);
			mint(account, 1000 ether);
			assertEq(_f3.balanceOf(account), 1000 ether);

			approveForTournament(account);
			approveForBox(account);

			buyBox(account, 10);
		}
	}

	function mint(address account, uint256 amount) public {
		_usdToken.mint(account, amount);
		vm.startPrank(me, me);
		_f3.mint(account, amount);
		vm.stopPrank();
	}

	function approveForTournament(address account) public {
		vm.startPrank(account, account);
		_f3.approve(address(_tournament), type(uint256).max);
		_f3NFT.setApprovalForAll(address(_tournament), true);
		vm.stopPrank();
	}

	function approveForBox(address account) public {
		vm.startPrank(account, account);
		_usdToken.approve(address(_f3Box), type(uint256).max);
		vm.stopPrank();
	}

	function buyBox(address account, uint256 quantity) public {
		vm.startPrank(account, account);
		_f3Box.buyBox(quantity, address(0));
		_f3Box.openBox(quantity);
		assertEq(_f3NFT.balanceOf(account), quantity);
		vm.stopPrank();
	}

	////////// TEST /////////////
	function testNFTBalance() public {
		for (uint160 i = 1; i <= totalPlayers; i++) {
			address account = _getAccount(i);
			vm.startPrank(account, account);
			assertEq(_f3NFT.balanceOf(account), 10);
			vm.stopPrank();
		}
		vm.startPrank(me, me);
	}

	function testSetDefenseTeam() public {
		for (uint160 i = 1; i <= totalPlayers; i++) {
			address account = _getAccount(i);
			_setDefenseTeam(account);
			assertEq(_f3NFT.balanceOf(account), 7);
		}
	}

	function testFunctions() public {
		for (uint160 i = 1; i <= totalPlayers; i++) {
			address account = _getAccount(i);
			_setDefenseTeam(account);
		}
		TournamentRBT.TournamentInfo memory tournamentInfo = _tournament.tournamentInfo();
		assertEq(tournamentInfo.totalPlayers, totalPlayers);
		uint256 expectedPoolReward = ((((3 * 10 * totalPlayers * 940) / 1000) * 7) / 10) * 1 ether;
		assertEq(tournamentInfo.poolReward, expectedPoolReward);
		assertEq(tournamentInfo.tournamentReward, (expectedPoolReward * 3) / 10);

		for (uint160 i = 1; i <= totalPlayers; i++) {
			address account = _getAccount(i);
			_battle(account);
		}

		TournamentRBT.PlayerRankInfo[] memory _rankTourPlayers = _tournament.roundRanks(0, 0, 160);
		for (uint i = 0; i < _rankTourPlayers.length; i++) {
			console.log("rank", i, _rankTourPlayers[i].player, _rankTourPlayers[i].score);
		}
		assertEq(_tournament.currentRound(), 3);

		skip(_DURATION);
		assertEq(_tournament.currentRound(), 4);
		_tournament.updateReward(false);
		address[] memory winners = _tournament.rankedFinalForRound(3);

		for (uint256 i = 0; i < winners.length; i++) {
			console.log("winner", i, winners[i]);
		}
	}

	function _setDefenseTeam(address account) internal {
		vm.startPrank(account, account);

		uint256[] memory tokenIds = new uint256[](3);
		for (uint256 i = 0; i < 3; i++) {
			tokenIds[i] = _f3NFT.tokenOfOwnerByIndex(account, i);
		}

		_tournament.pickSquad(tokenIds);
		vm.stopPrank();
	}

	function _battle(address account) internal {
		vm.startPrank(account, account);
		_tournament.battle();
		vm.stopPrank();
		skip(4);
	}
}
