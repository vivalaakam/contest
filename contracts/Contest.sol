// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract Contest {
    address public admin;
    string public name;
    uint public endTime;

    uint counter;
    uint public totalWinners;
    uint256 public ticketPrice;
    mapping(address => uint) public balance;
    mapping(address => uint[]) public ownedTickets;
    mapping(uint => address) public tickets;
    uint[] ticketKeys;
    uint[] public winners;
    bytes32 seed;
    Status public status = Status.OPEN;

    event ContestClosed(address contest);
    event ContestWinner(address winner, uint256 ticket, uint256 amount);
    event ContestParticipate(address winner, uint amount);

    enum Status {
        OPEN,
        CLOSED
    }

    constructor(
        uint _totalWinners,
        string memory _name,
        uint _endTime,
        uint256 _ticketPrice
    ) {
        admin = msg.sender;
        name = _name;
        endTime = _endTime;
        totalWinners = _totalWinners;
        ticketPrice = _ticketPrice;
    }

    function participate() public payable {
        require(status == Status.OPEN, "Contest closed");
        require(endTime == 0 || block.timestamp < endTime, "Contest closed");
        require(
            msg.value >= ticketPrice,
            "Not enough ether to purchase Ticket."
        );

        uint ticketId = counter;
        ownedTickets[msg.sender].push(ticketId);

        balance[msg.sender] += 1;
        tickets[ticketId] = msg.sender;
        ticketKeys.push(ticketId);

        seed = keccak256(
            abi.encodePacked(
                seed,
                block.timestamp,
                block.prevrandao,
                msg.sender
            )
        );

        counter += 1;
        emit ContestParticipate(msg.sender, ticketId);
    }

    function getWinners() public {
        require(msg.sender == admin, "Only admin node can get winners.");
        require(status == Status.OPEN, "Contest closed");
        uint total = totalWinners < counter ? totalWinners : counter;

        if (total == 0) {
            status = Status.CLOSED;
            emit ContestClosed(address(this));
            return;
        }

        uint256 amount = address(this).balance / total;

        for (uint i = 0; i < total; i++) {
            getWinner(amount);
        }

        status = Status.CLOSED;
        emit ContestClosed(address(this));
    }

    function getWinner(uint256 amount) private {
        seed = keccak256(
            abi.encodePacked(
                seed,
                block.timestamp,
                block.prevrandao,
                msg.sender
            )
        );

        uint256 winnerKey = uint(seed) % ticketKeys.length;
        uint winnerTicket = ticketKeys[winnerKey];
        address to = tickets[winnerTicket];

        ticketKeys[winnerKey] = ticketKeys[ticketKeys.length - 1];
        ticketKeys.pop();

        winners.push(winnerTicket);

        payable(to).transfer(amount);

        emit ContestWinner(to, winnerTicket, amount);
    }

    function getWinnersLength() public view returns (uint256) {
        return winners.length;
    }
}
