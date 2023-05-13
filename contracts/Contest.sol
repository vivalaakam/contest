pragma solidity ^0.8.9;

contract Contest {
    address public admin;
    string public name;
    string public description;
    uint public endTime;
    uint256 public totalWinners;
    mapping(address => uint256) public balance;
    mapping(address => bytes32[]) public ownedTickets;
    mapping(bytes32 => address) public tickets;
    bytes32[] ticketKeys;
    bytes32[] public winners;
    bytes32 seed;

    event ContestWinner(address indexed winner, bytes32 indexed ticket);


    constructor (address _admin, uint256 _totalWinners, string memory _name, string memory _description, uint _endTime) {
        admin = _admin;
        name = _name;
        endTime = _endTime;
        description = _description;
        totalWinners = _totalWinners;
    }

    function _participate(address participantAddress) internal returns (bytes32) {
        require(endTime == 0 || block.timestamp < endTime, "Contest closed");

        bytes32 rand = keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender));
        balance[participantAddress] += 1;
        tickets[rand] = participantAddress;
        ticketKeys.push(rand);
        seed = keccak256(abi.encodePacked(seed, rand));
        ownedTickets[participantAddress].push(rand);
        return rand;
    }

    function participate() external returns (bytes32) {
        return _participate(msg.sender);
    }

    function participateAdmin(address participantAddress) external returns (bytes32) {
        require(msg.sender == admin, "Only admin node can call participateAdmin");
        return _participate(participantAddress);
    }

    function getWinner() internal returns (bytes32) {
        bytes32 winnerSeed = keccak256(abi.encodePacked(seed, block.timestamp, block.prevrandao, msg.sender));
        uint256 key = uint256(winnerSeed) % ticketKeys.length;
        bytes32 winnerTicket = ticketKeys[key];
        ticketKeys[key] = ticketKeys[ticketKeys.length - 1];
        ticketKeys.pop();

        seed = keccak256(abi.encodePacked(seed, winnerSeed));

        winners.push(winnerTicket);

        emit ContestWinner(tickets[winnerTicket], winnerTicket);

        return winnerTicket;
    }

    function getWinners() external returns (bytes32[] memory) {
        require(msg.sender == admin, "Only admin node can get winners.");
        uint256 total = totalWinners < ticketKeys.length ? totalWinners : ticketKeys.length;

        for (uint256 i = 0; i < total; i++) {
            getWinner();
        }

        return winners;
    }

    function getWinnersLength() external view returns (uint256) {
        return winners.length;
    }
}

contract Contests {
    address[] public activeContests;
    address[] public closedContests;

    event ContestAdded(address indexed sender, address indexed contestAddress);

    function createContest(uint256 _totalWinners, string memory _name, string memory _description, uint _endTime) external returns (address) {
        Contest contest = new Contest(msg.sender, _totalWinners, _name, _description, _endTime);
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

    function closeContest(address contestAddress) external {
        Contest contest = Contest(contestAddress);
        require(msg.sender == contest.admin(), "Only admin node can close contest");

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
