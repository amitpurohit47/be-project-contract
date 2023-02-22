const main = async () => {
  const LandContract = await hre.ethers.getContractFactory("LandContract");
  const landContract = await LandContract.deploy(
    "0x5b14111F5D98064E8f9975A3EF8FBa6285f8136E"
  );

  await landContract.deployed();

  console.log(`Contract deployed at ${landContract.address}`);
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
};

runMain();
