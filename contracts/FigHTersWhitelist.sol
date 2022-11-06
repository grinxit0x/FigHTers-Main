//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/AccessControl.sol";

contract FigHTersWhitelist is AccessControl {

    bytes32 public constant WHITELIST_ADMIN_ROLE = keccak256("WHITELIST_ADMIN_ROLE");

    // Max number of whitelisted addresses allowed
    uint8 public maxWhitelistedAddresses;

    // Create a mapping of whitelistedAddresses
    // if an address is whitelisted, we would set it to true, it is false by default for all other addresses.
    mapping(address => bool) public whitelistedAddresses;

    // numAddressesWhitelisted would be used to keep track of how many addresses have been whitelisted
    // NOTE: Don't change this variable name, as it will be part of verification
    uint8 public numAddressesWhitelisted;

    // Setting the Max number of whitelisted addresses
    // User will put the value at the time of deployment
    constructor(uint8 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses =  _maxWhitelistedAddresses;
        //add msg.sender to the waitlist.
        addAddressToWhitelist(msg.sender);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(WHITELIST_ADMIN_ROLE, msg.sender);
    }

    /**
        addAddressToWhitelist - This function adds the address of the sender to the
        whitelist
     */
    function addAddressToWhitelist(address _add) public onlyRole(WHITELIST_ADMIN_ROLE) {
        // check if the user has already been whitelisted
        require(!whitelistedAddresses[_add], "Sender has already been whitelisted");
        // check if the numAddressesWhitelisted < maxWhitelistedAddresses, if not then throw an error.
        require(numAddressesWhitelisted < maxWhitelistedAddresses, "More addresses cant be added, limit reached");
        // Add the address which called the function to the whitelistedAddress array
        whitelistedAddresses[_add] = true;
        // Increase the number of whitelisted addresses
        numAddressesWhitelisted += 1;
    }

    function grantWhitelistAdminRole(address _add) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(WHITELIST_ADMIN_ROLE, _add);
    }
}