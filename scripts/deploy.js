const hre = require("hardhat");
const ethers = hre.ethers;
const fs = require("fs");
const path = require("path");

async function main() {
    if (network.name === "hardhat") {
        console.warn("Use the Hardhat option '--network localhost'");
    }


    const [deployer] = await ethers.getSigners();

    console.log("Deploying with", await deployer.getAddress())

    const CRCTShop = await ethers.getContractFactory("CRCTShop", deployer);
    const shop = await CRCTShop.deploy();
    await shop.deployed();

    saveFrontendFiles({
        CRCTShop: shop
    })
}


function saveFrontendFiles(contracts) {
    const contractsDir = path.join(__dirname, '/..', 'front/contracts')

    if (!fs.existsSync(contractsDir)) {
        fs.mkdirSync(contractsDir)
    }

    Object.entries(contracts).forEach((contract_item) => {
        const [name, contract] = contract_item;

        if (contract) {
            fs.writeFileSync(
                path.join(contractsDir, '/', name + '-contract-address.json'),
                JSON.stringify({[name]: contract.address}, undefined, 2)
            )
        }

        const ContractArtifact = hre.artifacts.readArtifactSync(name)

        fs.writeFileSync(
            path.join(contractsDir, '/', name + '.json'),
            JSON.stringify(ContractArtifact, null, 2)
        )
    })
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
