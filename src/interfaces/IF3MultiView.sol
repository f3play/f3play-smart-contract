pragma solidity ^0.8.19;

import "../interfaces/IF3NFT.sol";
import "../interfaces/IF3Box.sol";
import "../interfaces/ITournament.sol";
import "../interfaces/ILottery.sol";
import "../interfaces/IReferral.sol";

interface IF3MultiView {
	struct NFTView {
		uint256 id;
		IF3NFT.Attribute attribute;
	}

	struct OpenBoxHistoryView {
		address owner;
		NFTView[] nfts;
		uint256 tokenAmount;
		uint256 openedAt;
	}

	struct BattleHistoryView {
		address attacker;
		address defender;
		bool result;
		uint256 attackerScoreChange;
		uint256 defenderScoreChange;
		uint256 playedAt;
		NFTView[] attackerSquad;
		NFTView[] defenderSquad;
	}

	function nfts(address nftAddress_, address owner_, uint256 offset_, uint256 limit_) external view returns (NFTView[] memory);

	function openBoxHistory(
		address boxAddress_,
		address nft_,
		address owner_,
		uint256 offset_,
		uint256 limit_
	) external view returns (OpenBoxHistoryView[] memory);

	function battleHistory(
		address tournamentAddress_,
		address nft_,
		address player_,
		uint256 offset_,
		uint256 limit_
	) external view returns (BattleHistoryView[] memory);

	function lotteryHistory(
		address lotteryAddress_,
		uint256 offset_,
		uint256 limit_
	) external view returns (ILottery.LotteryRewardHistory[] memory);

	function refHistory(
		address refAddress_,
		address owner_,
		uint256 offset_,
		uint256 limit_
	) external view returns (IReferral.RefHistory[] memory);
}
