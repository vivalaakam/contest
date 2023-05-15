pragma solidity ^0.8.9;

contract Contest {
    address public admin;
    string public name;
    uint public endTime;

    uint counter;
    uint256 prizeAmount;
    uint public totalWinners;
    mapping(address => uint) public balance;
    mapping(address => uint[]) public ownedTickets;
    mapping(uint => address) public tickets;
    uint[] ticketKeys;
    uint[] public winners;
    bytes32 seed;
    Status status = Status.OPEN;

    event ContestWinner(address indexed winner, uint ticket, uint256 amount);

    enum Status{OPEN, CLOSED}

    constructor (address _admin, uint _totalWinners, string memory _name, uint _endTime) payable {
        admin = _admin;
        name = _name;
        endTime = _endTime;
        totalWinners = _totalWinners;
        prizeAmount = msg.value;
    }

    function _participate(address participantAddress) internal returns (uint) {
        require(status == Status.OPEN, "Contest closed");
        require(endTime == 0 || block.timestamp < endTime, "Contest closed");

        uint ticketId = counter;
        ownedTickets[participantAddress].push(ticketId);

        balance[participantAddress] += 1;
        tickets[ticketId] = participantAddress;
        ticketKeys.push(ticketId);

        bytes32 rand = keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender));
        seed = keccak256(abi.encodePacked(seed, rand));

        counter += 1;

        return ticketId;
    }

    function participate() external returns (uint) {
        return _participate(msg.sender);
    }

    function participateAdmin(address participantAddress) external returns (uint) {
        require(msg.sender == admin, "Only admin node can call participateAdmin");
        return _participate(participantAddress);
    }

    function getWinners() external payable {
        require(msg.sender == admin, "Only admin node can get winners.");
        require(status == Status.OPEN, "Contest closed");
        uint256 total = totalWinners < ticketKeys.length ? totalWinners : ticketKeys.length;
        uint256 amount = prizeAmount / total;
        for (uint256 i = 0; i < total; i++) {
            bytes32 winnerSeed = keccak256(abi.encodePacked(seed, block.timestamp, block.prevrandao, msg.sender));

            uint key = uint256(winnerSeed) % ticketKeys.length;
            uint winnerTicket = ticketKeys[key];

            ticketKeys[key] = ticketKeys[ticketKeys.length - 1];
            ticketKeys.pop();

            seed = keccak256(abi.encodePacked(seed, winnerSeed));

            winners.push(winnerTicket);

            payable(tickets[winnerTicket]).transfer(amount);

            emit ContestWinner(tickets[winnerTicket], winnerTicket, amount);
        }

        status = Status.CLOSED;
    }

    function getWinnersLength() external view returns (uint256) {
        return winners.length;
    }
}

contract Contests {
    address[] public activeContests;
    address[] public closedContests;

    event ContestAdded(address indexed sender, address indexed contestAddress);

    function createContest(uint256 _totalWinners, string memory _name, uint _endTime) external payable returns (address) {
        Contest contest = new Contest{value: msg.value}(msg.sender, _totalWinners, _name, _endTime);
        address addr = address(contest);
        activeContests.push(addr);

        emit ContestAdded(msg.sender, addr);

        return addr;
    }

    function getActiveContests() public view returns (address[] memory) {
        return activeContests;
    }

    function getClosedContests() public view returns (address[] memory) {
        return closedContests;
    }

    function closeContest(address contestAddress) external payable {
        Contest contest = Contest(contestAddress);
        require(msg.sender == contest.admin(), "Only admin node can close contest");

        (bool success, bytes memory data) = contestAddress.delegatecall(
            abi.encodeWithSelector(Contest.getWinners.selector)
        );

        require(success, string(data));

        closedContests.push(contestAddress);

        if (activeContests.length > 1) {
            uint indexToBeDeleted = activeContests.length;

            for (uint i = 0; i < activeContests.length; i++) {
                if (activeContests[i] == contestAddress) {
                    indexToBeDeleted = i;
                    break;
                }
            }

            if (indexToBeDeleted < activeContests.length - 2) {
                activeContests[indexToBeDeleted] = activeContests[activeContests.length - 1];
            }
        }

        activeContests.pop();
    }
}
