import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { Config } from "../scripts/config";

import {
    StoreFactory__factory,
    NftMarketPlace__factory,
    StoreFactory,
    NftMarketPlace,
} from "../typechain-types";

describe("Greater", () => {
    let user: SignerWithAddress;
    let nftMarketPlace: NftMarketPlace;
    let storeFactory: StoreFactory;

    beforeEach(async () => {
        const accounts: SignerWithAddress[] = await ethers.getSigners();
        user = accounts[0];

        const NftMarketPlaceFactory: NftMarketPlace__factory =
            await ethers.getContractFactory("NftMarketPlace");

        const StoreFactory: StoreFactory__factory =
            await ethers.getContractFactory("StoreFactory");
        nftMarketPlace = await NftMarketPlaceFactory.deploy();
        storeFactory = await StoreFactory.deploy(
            Config.project,
            Config.adminRouter,
            Config.transferRouter,
            nftMarketPlace.address,
        );
    });

    describe("Deployment", () => {
        it("Should deploy successfully", async () => {});
    });

    describe("Create store", () => {
        it("Should create successfully", async () => {
            await storeFactory
                .connect(user)
                .createStore(
                    "_name",
                    "_symbol",
                    "_image",
                    "_profile",
                    "_description",
                );
        });

        it("Should mint and list successfully", async () => {
            await storeFactory
                .connect(user)
                .createStore(
                    "_name",
                    "_symbol",
                    "_image",
                    "_profile",
                    "_description",
                );
            await storeFactory
                .connect(user)
                .mintAndListNewTypeId(
                    0,
                    "this is uri",
                    10,
                    1000,
                    ethers.constants.AddressZero,
                    1680150088,
                );

            await storeFactory
                .connect(user)
                .mintAndListNewTypeId(
                    0,
                    "",
                    2,
                    1000,
                    ethers.constants.AddressZero,
                    0,
                );
            await storeFactory.connect(user).mintAndListExistingTypeId(0, 0, 2);
            await storeFactory.connect(user).mintAndListExistingTypeId(0, 0, 5);

            await storeFactory
                .connect(user)
                .mintAndListNewTypeId(
                    0,
                    "",
                    5,
                    1000,
                    ethers.constants.AddressZero,
                    0,
                );
            await storeFactory
                .connect(user)
                .mintAndListExistingTypeId(0, 131072, 10);
            await storeFactory
                .connect(user)
                .createStore(
                    "_name",
                    "_symbol",
                    "_image",
                    "_profile",
                    "_description",
                );
            await storeFactory
                .connect(user)
                .mintAndListNewTypeId(
                    1,
                    "",
                    1,
                    1000,
                    ethers.constants.AddressZero,
                    0,
                );
            console.log(
                await nftMarketPlace.getAllOpenTradeIdByStore(
                    (
                        await storeFactory.getStoreInfo(0)
                    ).storeAddress,
                ),
            );

            await expect(
                nftMarketPlace.completeTrade(1, { value: 999 }),
            ).to.revertedWith("Insufficient price amount");
            await nftMarketPlace.completeTrade(1, { value: 1000 });

            await nftMarketPlace.completeTrade(3, { value: 1001 });

            await nftMarketPlace.closeTrade(2);
            console.log(await nftMarketPlace.getOpenTradeIdAll());
            await nftMarketPlace.batchCompleteTrade([1, 1, 1], { value: 3000 });
            console.log(
                await nftMarketPlace.getOpenTradeInfoByStoreByPage(
                    (
                        await storeFactory.getStoreInfo(0)
                    ).storeAddress,
                    1,
                    5,
                ),
            );
            await nftMarketPlace.batchCloseTrade([1, 3]);
        });
    });
});
