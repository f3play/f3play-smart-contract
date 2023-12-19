pragma solidity ^0.8.19;

import "../interfaces/IF3MultiView.sol";

contract F3MultiView is IF3MultiView {
	function nfts(address nftAddress_, address owner_, uint256 offset_, uint256 limit_) external view returns (NFTView[] memory) {
		IF3NFT nft = IF3NFT(nftAddress_);

		uint256 total = nft.balanceOf(owner_);
		uint256 to = offset_ + limit_;

		if (to > total) {
			to = total;
		}

		NFTView[] memory nftViews = new NFTView[](to - offset_);

		for (uint256 i = offset_; i < to; i++) {
			nftViews[i - offset_] = NFTView({
				id: nft.tokenOfOwnerByIndex(owner_, i),
				attribute: nft.attributes(nft.tokenOfOwnerByIndex(owner_, i))
			});
		}

		return nftViews;
	}

	function openBoxHistory(
		address boxAddress_,
		address nft_,
		address owner_,
		uint256 offset_,
		uint256 limit_
	) external view returns (OpenBoxHistoryView[] memory) {
		IF3Box box = IF3Box(boxAddress_);
		IF3NFT nft = IF3NFT(nft_);
		uint256 total = box.openBoxHistoryCounter(owner_);
		uint256 to = offset_ + limit_;

		if (to > total) {
			to = total;
		}

		OpenBoxHistoryView[] memory openBoxHistoryViews = new OpenBoxHistoryView[](to - offset_);

		for (uint256 i = offset_; i < to; i++) {
			IF3Box.OpenBoxHistory memory openBoxHistoryI = box.openBoxHistories(owner_, i);
			uint256 nftLength = openBoxHistoryI.nfts.length;
			NFTView[] memory nftViews = new NFTView[](nftLength);

			for (uint256 j = 0; j < nftLength; j++) {
				uint256 nftId = openBoxHistoryI.nfts[j];
				nftViews[j] = NFTView({ id: nftId, attribute: nft.attributes(nftId) });
			}

			openBoxHistoryViews[i - offset_] = OpenBoxHistoryView({
				owner: openBoxHistoryI.owner,
				nfts: nftViews,
				tokenAmount: openBoxHistoryI.tokenAmount,
				openedAt: openBoxHistoryI.openedAt
			});
		}

		return openBoxHistoryViews;
	}

	function battleHistory(
		address tournamentAddress_,
		address nft_,
		address player_,
		uint256 offset_,
		uint256 limit_
	) external view returns (BattleHistoryView[] memory) {
		ITournament tournament = ITournament(tournamentAddress_);
		IF3NFT nft = IF3NFT(nft_);
		uint256 total = tournament.battleHistoryCounter(player_);
		uint256 to = offset_ + limit_;

		if (to > total) {
			to = total;
		}

		BattleHistoryView[] memory battleHistoryViews = new BattleHistoryView[](to - offset_);

		ITournament.BattleHistory[] memory mBattleHistory = tournament.battleHistories(player_, offset_, limit_);

		for (uint256 i = 0; i < to - offset_; i++) {
			ITournament.BattleHistory memory battleHistoryI = mBattleHistory[i];
			uint256 attackerSquadLength = battleHistoryI.attackerSquad.length;
			NFTView[] memory attackerSquadViews = new NFTView[](attackerSquadLength);

			for (uint256 j = 0; j < attackerSquadLength; j++) {
				uint256 nftId = battleHistoryI.attackerSquad[j];
				attackerSquadViews[j] = NFTView({ id: nftId, attribute: nft.attributes(nftId) });
			}

			uint256 defenderSquadLength = battleHistoryI.defenderSquad.length;
			NFTView[] memory defenderSquadViews = new NFTView[](defenderSquadLength);

			for (uint256 j = 0; j < defenderSquadLength; j++) {
				uint256 nftId = battleHistoryI.defenderSquad[j];
				defenderSquadViews[j] = NFTView({ id: nftId, attribute: nft.attributes(nftId) });
			}

			battleHistoryViews[i] = BattleHistoryView({
				attacker: battleHistoryI.attacker,
				defender: battleHistoryI.defender,
				result: battleHistoryI.result,
				attackerScoreChange: battleHistoryI.attackerScoreChange,
				defenderScoreChange: battleHistoryI.defenderScoreChange,
				playedAt: battleHistoryI.playedAt,
				attackerSquad: attackerSquadViews,
				defenderSquad: defenderSquadViews
			});
		}

		return battleHistoryViews;
	}

	function lotteryHistory(
		address lotteryAddress_,
		uint256 offset_,
		uint256 limit_
	) external view returns (ILottery.LotteryRewardHistory[] memory) {
		ILottery lottery = ILottery(lotteryAddress_);
		uint256 total = lottery.lotteryRewardHistoryCounter();
		uint256 to = offset_ + limit_;

		if (to > total) {
			to = total;
		}

		ILottery.LotteryRewardHistory[] memory lotteryRewardHistories = new ILottery.LotteryRewardHistory[](to - offset_);

		for (uint256 i = offset_; i < to; i++) {
			lotteryRewardHistories[i - offset_] = lottery.lotteryRewardHistory(i);
		}

		return lotteryRewardHistories;
	}

	function refHistory(
		address refAddress_,
		address owner,
		uint256 offset_,
		uint256 limit_
	) external view returns (IReferral.RefHistory[] memory) {
		IReferral ref = IReferral(refAddress_);

		uint256 total = ref.refHistoryCounter(owner);
		uint256 to = offset_ + limit_;
		if (to > total) {
			to = total;
		}

		IReferral.RefHistory[] memory refHistories = new IReferral.RefHistory[](to - offset_);

		for (uint256 i = offset_; i < to; i++) {
			refHistories[i - offset_] = ref.refHistory(owner, i);
		}

		return refHistories;
	}
}
