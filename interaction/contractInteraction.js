const { ethers } = require('ethers');
const fs = require('fs');
const path = require('path');

const provider = new ethers.providers.JsonRpcProvider('http://localhost:8545');

const abiPath = path.resolve(__dirname, '../foundry-games/out/src/CoinFlip.sol/CoinFlip.json');

const contractABI = JSON.parse(fs.readFileSync(abiPath, 'utf8')).abi;

const contractAddress = '0x662EdB52d7469D29a72deEA6602d90eFf0cEB46E';

const coinFlipContract = new ethers.Contract(contractAddress, contractABI, provider);

async function placeBet(userAddress, betAmount, choice) {
  const signer = provider.getSigner(userAddress);
  const contractWithSigner = coinFlipContract.connect(signer);
  const tx = await contractWithSigner.placeBet(choice, { value: ethers.utils.parseEther(betAmount.toString()) });
  await tx.wait();
}

async function getBalance(userAddress) {
  const balance = await coinFlipContract.getBalance({ from: userAddress });
  return ethers.utils.formatEther(balance);
}

module.exports = {
  placeBet,
  getBalance
};
