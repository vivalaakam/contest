import {ethers} from "hardhat";

async function main() {
    const Contest = await ethers.getContractFactory("Contests");
    const lock = await Contest.deploy();

    await lock.deployed();
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
