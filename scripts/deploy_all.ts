import * as hre from "hardhat";
import * as fs from "fs";
import { Signer } from "ethers";
const ethers = hre.ethers;
import { Config } from "./config";

import {
    StoreFactory__factory,
    NftMarketPlace__factory,
    StoreFactory,
    NftMarketPlace,
} from "../typechain-types";

async function main() {
    //Loading accounts
    const accounts: Signer[] = await ethers.getSigners();
    const admin = await accounts[0].getAddress();
    //Loading contracts' factory

    const NftMarketPlaceFactory: NftMarketPlace__factory =
        await ethers.getContractFactory("NftMarketPlace");

    const StoreFactory: StoreFactory__factory = await ethers.getContractFactory(
        "StoreFactory",
    );

    // Deploy contracts
    console.log(
        "==================================================================",
    );
    console.log("DEPLOY CONTRACTS");
    console.log(
        "==================================================================",
    );

    console.log("ACCOUNT: " + admin);

    const nftMarketPlace: NftMarketPlace = await NftMarketPlaceFactory.deploy();

    console.log("NFTMarketPlace deployed at: ", nftMarketPlace.address);

    const storeFactory: StoreFactory = await StoreFactory.deploy(
        Config.project,
        Config.adminRouter,
        Config.transferRouter,
        nftMarketPlace.address,
    );

    console.log("StoreFactory deployed at: ", storeFactory.address);

    const contractAddress = {
        nftMarketPlace: nftMarketPlace.address,
        storeFactory: storeFactory.address,
    };

    fs.writeFileSync("contracts.json", JSON.stringify(contractAddress));
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
