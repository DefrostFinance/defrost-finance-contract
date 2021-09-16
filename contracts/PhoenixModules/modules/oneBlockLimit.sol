
pragma solidity =0.5.16;
contract oneBlockLimit {

  /**
   * @dev We use a single lock for the whole contract.
   */
  mapping(address=>uint256) private lastBlockMap;
  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier OneBlockLimit(address account) {
    require(lastBlockMap[account] != block.number,"Contract cannot run again in one block");
    lastBlockMap[account] = block.number;
    _;
  }

}