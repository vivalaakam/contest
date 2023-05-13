import {ethers} from "hardhat";
import {loadFixture, time} from "@nomicfoundation/hardhat-network-helpers";
import {expect} from "chai";
import {Contests} from "../typechain-types";
import {Signer} from "ethers";

const CONTEST_NAME = "test name";
const CONTEST_DESCRIPTION = "test description";

describe("Contest", function () {
    async function deployOneYearLockFixture() {
        const endTime = (await time.latest()) + 60;

        const [owner, participant1, participant2, participant3, participant4, participant5] = await ethers.getSigners();

        const Contest = await ethers.getContractFactory("Contests");
        const contest = await Contest.deploy();

        return {contest, endTime, owner, participant1, participant2, participant3, participant4, participant5};
    }

    async function deployContest(contest: Contests, owner: Signer, endTime: number) {
        const tx = await contest.connect(owner).createContest(10, CONTEST_NAME, CONTEST_DESCRIPTION, endTime);
        const receipt = await tx.wait();

        let event

        if (receipt.events) {
            event = receipt.events.find(event => event?.event === 'ContestAdded')
        }

        return event?.args?.contestAddress;
    }

    it('should create and close contest', async () => {
        const {contest, owner, endTime, participant1} = await loadFixture(deployOneYearLockFixture);
        const contestAddress = await deployContest(contest, owner, endTime);

        const activeContests = await contest.getActiveContests();

        expect(activeContests.length).to.be.equal(1);
        expect(activeContests).to.be.include(contestAddress);

        await contest.connect(owner).closeContest(contestAddress);
        const activeContestsClosed = await contest.getActiveContests();
        expect(activeContestsClosed.length).to.be.equal(0);

        const closedContests = await contest.getClosedContests();

        expect(closedContests.length).to.be.equal(1);
        expect(closedContests).to.be.include(contestAddress);
    });

    it('should create and close few contest', async () => {
        const {contest, owner, endTime, participant1} = await loadFixture(deployOneYearLockFixture);

        const contestAddress1 = await deployContest(contest, owner, endTime)
        const contestAddress2 = await deployContest(contest, owner, endTime)
        const contestAddress3 = await deployContest(contest, owner, endTime)

        const activeContests = await contest.getActiveContests();

        expect(activeContests.length).to.be.equal(3);
        expect(activeContests).to.be.include(contestAddress1);
        expect(activeContests).to.be.include(contestAddress2);
        expect(activeContests).to.be.include(contestAddress3);

        await contest.connect(owner).closeContest(contestAddress1);
        const activeContestsClosed = await contest.getActiveContests();
        expect(activeContestsClosed.length).to.be.equal(2);
        expect(activeContestsClosed).to.be.include(contestAddress2);
        expect(activeContestsClosed).to.be.include(contestAddress3);

        const closedContests = await contest.getClosedContests();

        expect(closedContests.length).to.be.equal(1);
        expect(closedContests).to.be.include(contestAddress1);
    });
});
