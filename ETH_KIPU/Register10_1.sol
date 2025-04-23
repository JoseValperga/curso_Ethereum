// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title Concepts: White List using Array
contract Register10_1 {
    address[] private whiteList;

    /**
     * Add an address to the white list
     * @dev Adds the address to the array if it is not already present
     * @param addr The address to be added
     */
    function addToWhiteList(address addr) external {
        require(!isInWhiteList(addr), "Address already in white list");
        whiteList.push(addr);
    }

    /**
     * Check if an address is in the white list
     * @dev Loops through the array to check if the address exists
     * @param addr The address to check
     * @return bool True if the address is in the white list, false otherwise
     */
    function isInWhiteList(address addr) public view returns (bool) {
        for (uint i = 0; i < whiteList.length; i++) {
            if (whiteList[i] == addr) {
                return true;
            }
        }
        return false;
    }

    /**
     * Get all addresses in the white list
     * @dev Returns the entire array of white listed addresses
     * @return address[] The array of white listed addresses
     */
    function getWhiteList() external view returns (address[] memory) {
        return whiteList;
    }
}
