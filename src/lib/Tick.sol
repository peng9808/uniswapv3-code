// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;

library Tick {
	struct Info {
		bool initialuzed;
		uint128 liquidity;
	}

	function update (
		mapping(int24 => Tick.Info) storage self,
		int24 tick,
		uint128 liquidityDelta
	) internal {
		Tick.Info storage info = self[tick];
		if (info.initialuzed) {
			info.liquidity += liquidityDelta;
		} else {
			info.initialuzed = true;
			info.liquidity = liquidityDelta;
		}
	}
}