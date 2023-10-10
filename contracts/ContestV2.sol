// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ContestV2 is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private counter;

    address public admin;
    string public name;
    uint public endTime;

    uint256 prizeAmount;
    uint256 public totalWinners;
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
        uint256 _totalWinners,
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

    function participate() external payable {
        require(status == Status.OPEN, "Contest closed");
        require(endTime == 0 || block.timestamp < endTime, "Contest closed");
        require(
            msg.value >= ticketPrice,
            "Not enough ether to purchase Ticket."
        );

        uint ticketId = counter.current();

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

        counter.increment();
        emit ContestParticipate(msg.sender, ticketId);
    }

    function getWinners() external payable onlyOwner {
        require(status == Status.OPEN, "Contest closed");
        uint count = uint(counter.current());
        uint total = totalWinners < count ? totalWinners : count;

        if (total == 0) {
            status = Status.CLOSED;
            emit ContestClosed(address(this));
            return;
        }

        uint256 winnerKey = uint(seed);

        uint t = total < ticketKeys.length ? total : ticketKeys.length;
        uint256 amount = address(this).balance / t;

        for (uint i = 0; i < t; i++) {
            winnerKey =
                uint(
                    keccak256(
                        abi.encodePacked(
                            winnerKey,
                            block.timestamp,
                            block.prevrandao,
                            msg.sender
                        )
                    )
                ) %
                ticketKeys.length;
            uint winnerTicket = ticketKeys[winnerKey];
            address to = tickets[winnerTicket];

            ticketKeys[winnerKey] = ticketKeys[ticketKeys.length - 1];
            ticketKeys.pop();

            winners.push(winnerTicket);

            payable(to).transfer(amount);

            emit ContestWinner(to, winnerTicket, amount);
        }

        if (winners.length == total) {
            status = Status.CLOSED;
            emit ContestClosed(address(this));
        }
    }

    function getWinnersLength() external view returns (uint256) {
        return winners.length;
    }
}
