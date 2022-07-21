//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FundMe {

    uint256 public minimumUsd = 50 * 1e18;
    
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded; 

    function fund() public payable{
        // Want to be able to set a minimum fund amount in USD
        //How do we send ETH to this contract?
        require(getConversionRate(msg.value) >= minimumUsd, "Didn't send enough. "); // 1e18 == 1 * 10 ** 18 == 1000000000000000000 // to check how much value someone is sending. 
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    } 

    function getPrice() public view returns(uint256) {
        //ABI
        //Address of the other contract 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e 
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 price,,,) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    function withdraw() public {
        for(uint funderIndex = 0; funderIndex < funders.length; funderIndex = funderIndex ++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);
        //actually withdraw the funds

        //transfer
        payable(msg.sender).transfer(address(this).balance);
        //send 
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");
        //call
        (bool callSuccess, bytes dataReturned) = payable(msg.sender).call{value: address(this).balance}("");
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

}