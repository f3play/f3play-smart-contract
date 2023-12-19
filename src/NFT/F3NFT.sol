pragma solidity ^0.8.19;
import "openzeppelin/token/ERC721/IERC721.sol";
import "openzeppelin/token/ERC721/extensions/IERC721Enumerable.sol";
import "./BaseF3NFT.sol";

contract F3NFT is BaseF3NFT {
	address public feeReceiver;
	error MisMatchedMaterialNFTsLength();

	event NFTUpgraded(uint256 indexed tokenId, uint256[] materialNFTs);

	mapping(uint32 => uint32[]) private _upgradeRequirement;

	constructor(address f3Token_) BaseF3NFT(f3Token_) {
		feeReceiver = msg.sender;
		_setUpRequirement();
	}

	function _setUpRequirement() internal {
		_upgradeRequirement[0] = [2, 0, 0, 0];
		_upgradeRequirement[1] = [1, 1, 0, 0];
		_upgradeRequirement[2] = [1, 2, 0, 0];
		_upgradeRequirement[3] = [2, 2, 0, 0];
		_upgradeRequirement[4] = [3, 0, 0, 0];
		_upgradeRequirement[5] = [2, 2, 0, 0];
		_upgradeRequirement[6] = [3, 2, 0, 0];
		_upgradeRequirement[7] = [2, 2, 1, 0];
		_upgradeRequirement[8] = [3, 2, 1, 0];
		_upgradeRequirement[9] = [0, 0, 0, 1];
		_upgradeRequirement[10] = [5, 0, 0, 0];
		_upgradeRequirement[11] = [4, 3, 0, 0];
		_upgradeRequirement[12] = [3, 3, 2, 0];
		_upgradeRequirement[13] = [4, 2, 2, 0];
		_upgradeRequirement[14] = [6, 1, 0, 0];
		_upgradeRequirement[15] = [3, 4, 0, 0];
		_upgradeRequirement[16] = [5, 4, 0, 0];
		_upgradeRequirement[17] = [4, 4, 3, 0];
		_upgradeRequirement[18] = [5, 3, 3, 1];
		_upgradeRequirement[19] = [7, 2, 0, 0];
		_upgradeRequirement[20] = [0, 0, 0, 2];
	}

	function setFeeReceiver(address feeReceiver_) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(feeReceiver_ != address(0), "F3NFT: feeReceiver_");
		feeReceiver = feeReceiver_;
	}

	function upgrade(uint256 tokenId_, uint256[] calldata materialNFTs_) external {
		if (msg.sender != ownerOf(tokenId_)) {
			revert NotOwner();
		}

		uint256 mUpgradeCost = upgradeCost(_attributes[tokenId_].level);

		if (mUpgradeCost > 0) {
			f3Token.transferFrom(msg.sender, feeReceiver, mUpgradeCost);
		}

		_attributes[tokenId_] = upgradePreview(tokenId_, materialNFTs_);

		for (uint256 i = 0; i < materialNFTs_.length; i++) {
            uint256 materialId = materialNFTs_[i];
			if (msg.sender != ownerOf(materialId)) {
				revert NotOwner();
			}
			_burn(materialId);
		}

		emit NFTUpgraded(tokenId_, materialNFTs_);
	}

	function upgradePreview(uint256 tokenId_, uint256[] calldata materialNFTs_) public view returns (Attribute memory) {
		Attribute memory attribute = _attributes[tokenId_];

		uint32[] memory requirement = requirementOfLevel(attribute.level);

		uint32 i = 0;

		uint32 materialRate = 0;
		uint32 materialAttack = 0;
		uint32 materialDefense = 0;

		for (uint32 rarity = 0; rarity < 4; rarity++) {
			if (requirement[rarity] == 0) {
				continue;
			}
			for (uint32 k = 0; k < requirement[rarity]; k++) {
				uint256 materialId = materialNFTs_[i];
				if (materialId == tokenId_) {
					revert CannotUseItselfToUpgrade();
				}

				Attribute memory materialAttribute = _attributes[materialId];

				materialRate += materialAttribute.hashRate;
				materialAttack += materialAttribute.attack;
				materialDefense += materialAttribute.defense;

				if (materialAttribute.element != attribute.element) {
					revert InvalidElementMaterial();
				}

				if (msg.sender != ownerOf(materialId)) {
					revert NotOwner();
				}

				if (rarity == 3) {
					if (materialAttribute.rarity != attribute.rarity) {
						revert InvalidRarityMaterial();
					}
				} else if (materialAttribute.rarity != rarity + 1) {
					revert InvalidRarityMaterial();
				}

				unchecked {
					i++;
				}
			}
		}

		if (i != materialNFTs_.length) {
			revert MisMatchedMaterialNFTsLength();
		}

		attribute.level++;
		attribute.hashRate = _newPower(attribute.hashRate, materialRate, attribute.baseRate);
		attribute.attack = _newPower(attribute.attack, materialAttack, attribute.baseAttack);
		attribute.defense = _newPower(attribute.defense, materialDefense, attribute.baseDefense);

		return attribute;
	}

	function requirementOfLevel(uint32 level) public view returns (uint32[] memory) {
		return _upgradeRequirement[level - 1];
	}

	function upgradeCost(uint32 level) public pure returns (uint256 cost) {
		return uint256(level) * 300 ether;
	}

	function _newPower(uint32 previous_, uint32 materials_, uint16 base_) internal pure returns (uint32) {
		return previous_ + (materials_ * 12) / 10 + (uint32(base_) * 2) / 10;
	}
}
