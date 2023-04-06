import * as hre from "hardhat";
import * as fs from "fs";
import { Signer } from "ethers";
const ethers = hre.ethers;
import { Config } from "./config";

import {
    StoreFactory__factory,
    NftMarketPlace__factory,
    Store__factory,
    StoreFactory,
    NftMarketPlace,
    Store,
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

    const Store: Store__factory = await ethers.getContractFactory("Store");

    // Deploy contracts
    console.log(
        "==================================================================",
    );
    console.log("ATTACH CONTRACTS");
    console.log(
        "==================================================================",
    );

    console.log("ACCOUNT: " + admin);

    const storeFactory: StoreFactory = StoreFactory.attach(
        "0xdc5D44D8efCef938f0b2CdD03d7bA2E9b14691B1",
    );

    const nftMarketPlace: NftMarketPlace = NftMarketPlaceFactory.attach(
        "0x2f7eFbEd08cBc5ED2A2CBF8a3220e2b2B1b4b95c",
    );

    const store: Store = Store.attach(
        "0x2219654cd791553f0c51e7fb39df6321635c2ac0",
    );

    console.log(await nftMarketPlace.getTradeInfoById(1));
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
