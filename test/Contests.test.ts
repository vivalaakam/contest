import {ethers} from "hardhat";
import {loadFixture, time} from "@nomicfoundation/hardhat-network-helpers";
import {expect} from "chai";

const CONTEST_NAME = "test name";
const CONTEST_DESCRIPTION = "test description";

describe("Contest", function () {
    async function deployOneYearLockFixture() {
        const endTime = (await time.latest()) + 60;

        const [owner, participant1, participant2, participant3, participant4, participant5] = await ethers.getSigners();

        const Contest = await ethers.getContractFactory("Contest");
        const contest = await Contest.deploy(owner.getAddress(), 10, CONTEST_NAME, CONTEST_DESCRIPTION, endTime);

        return {contest, endTime, owner, participant1, participant2, participant3, participant4, participant5};
    }

    it('should get name and description', async () => {
        const {contest, endTime} = await loadFixture(deployOneYearLockFixture);
        expect(await contest.name()).to.be.equal("test name");
        expect(await contest.description()).to.be.equal("test description");
        expect(await contest.endTime()).to.be.equal(endTime);
    });

    it("should provide to participate", async () => {
        const {contest, participant1, participant2} = await loadFixture(deployOneYearLockFixture);

        expect(await contest.connect(participant1).participate()).to.be.exist;
        expect(await contest.connect(participant1).participate()).to.be.exist;
        expect(await contest.connect(participant2).participate()).to.be.exist;

        expect(await contest.balance(participant1.getAddress())).to.be.equal(2);
        expect(await contest.balance(participant2.getAddress())).to.be.equal(1);

        expect(await contest.getWinners()).to.be.exist;
        expect(await contest.getWinnersLength()).to.be.equal(3);
    });

    it("should select winners less than maximum", async () => {
        const {contest, participant1, participant2} = await loadFixture(deployOneYearLockFixture);

        await contest.connect(participant1).participate();
        await contest.connect(participant1).participate();
        await contest.connect(participant2).participate();

        expect(await contest.balance(participant1.getAddress())).to.be.equal(2);
        expect(await contest.balance(participant2.getAddress())).to.be.equal(1);

        expect(await contest.getWinners()).to.be.exist;
        expect(await contest.getWinnersLength()).to.be.equal(3);
    });

    it("should select winners", async () => {
        const {
            contest,
            participant1,
            participant2,
            participant3,
            participant4,
            participant5
        } = await loadFixture(deployOneYearLockFixture);

        for (let i = 0; i < 3; i += 1) {
            await contest.connect(participant1).participate()
            await contest.connect(participant2).participate()
            await contest.connect(participant3).participate()
            await contest.connect(participant4).participate()
            await contest.connect(participant5).participate()
        }

        expect(await contest.balance(participant1.getAddress())).to.be.equal(3);
        expect(await contest.balance(participant2.getAddress())).to.be.equal(3);
        expect(await contest.balance(participant3.getAddress())).to.be.equal(3);
        expect(await contest.balance(participant4.getAddress())).to.be.equal(3);
        expect(await contest.balance(participant5.getAddress())).to.be.equal(3);

        expect(await contest.getWinners()).to.be.exist;
        expect(await contest.getWinnersLength()).to.be.equal(10);
    });

    it("should set admin participants", async () => {
        const {
            contest,
            owner,
            participant1,
            participant2,
        } = await loadFixture(deployOneYearLockFixture);

        await expect(contest.connect(participant1).participateAdmin(participant2.getAddress())).to.be.revertedWith("Only admin node can call participateAdmin");
        expect(await contest.balance(participant2.getAddress())).to.be.equal(0);

        await contest.connect(owner).participateAdmin(participant2.getAddress());
        expect(await contest.balance(participant2.getAddress())).to.be.equal(1);
    })

    it("should not apply participant if date is end", async () => {
        const endTime = (await time.latest()) - 60;

        const [owner, participant1] = await ethers.getSigners();

        const Contest = await ethers.getContractFactory("Contest");
        const contest = await Contest.deploy(owner.getAddress(), 10, CONTEST_NAME, CONTEST_DESCRIPTION, endTime);

        await expect(contest.connect(participant1).participate()).to.be.revertedWith("Contest closed");
    })

    it("should apply participant if date is 0", async () => {
        const [owner, participant1] = await ethers.getSigners();

        const Contest = await ethers.getContractFactory("Contest");
        const contest = await Contest.deploy(owner.getAddress(), 10, CONTEST_NAME, CONTEST_DESCRIPTION, 0);

        await contest.connect(participant1).participate();
        expect(await contest.balance(participant1.getAddress())).to.be.equal(1);
    })
});
