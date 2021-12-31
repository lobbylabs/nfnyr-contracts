const fs = require("fs");
const ethers = require("ethers");

const uri = "QmW9Heq1jpoLyqbwnVoGHCgxj6jdNk5konhypGdph16Q97";

let localDeployerMnemonic = fs.readFileSync("./mnemonic.txt");
localDeployerMnemonic = localDeployerMnemonic.toString().trim();

const wallet = ethers.Wallet.fromMnemonic(localDeployerMnemonic);
const uriHash = ethers.utils.keccak256(Buffer.from(uri));
const binary = ethers.utils.arrayify(uriHash);

wallet.signMessage(binary).then((sig) => {
  console.log("uri: ", uri);
  console.log("signing wallet address: ", wallet.address);
  console.log("signature: ", sig);
  console.log("signature split: ", ethers.utils.splitSignature(sig));
});
