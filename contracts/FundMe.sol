// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

import "./PriceConverter.sol";

error SendAmountNotEnough();
error CallFailed();
error NotOwner();

// 859757
// 840209
contract FundMe {
    using PriceConverter for uint256;

    // 23515 when not constant
    // 21415 when constant
    uint256 public constant MINIMUM_USD = 50 * 1e18; // 1 * 10 ** 18

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    // 23622 when not immutable
    // 21486 when immutable
    address public immutable i_owner;

    constructor() {
        i_owner = msg.sender;
    }

    function fund() public payable {
        // require(msg.value.getConversionRate() >= MINIMUM_USD, "Did not send enough!"); // 1e18 == 1 * 10 **18 == 1000000000000000000
        if (msg.value.getConversionRate() < MINIMUM_USD) {
            revert SendAmountNotEnough();
        }

        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // funders variable is set to an array of type address with a length of 0
        funders = new address[](0);

        // // transfer
        // payable(msg.sender).transfer(address[this].balance);
        // // send
        // bool sendSuccess = payable(msg.sender).send(address[this].balance);
        // require(sendSuccess, "Send Failed")
        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        // require(callSuccess, "Call Failed");
        if (!callSuccess) {
            revert CallFailed();
        }
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }

        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}
