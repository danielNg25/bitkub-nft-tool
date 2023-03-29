import * as hre from "hardhat";
import * as contracts from "../contracts.json";
import { Config } from "./config";

async function main() {
    try {
        await hre.run("verify:verify", {
            address: contracts.storeFactory,
            constructorArguments: [
                Config.project,
                Config.adminRouter,
                Config.transferRouter,
            ],
            hre,
        });
    } catch (err) {
        console.log("err >>", err);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
