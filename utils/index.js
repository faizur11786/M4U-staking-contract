const { writeFileSync } = require("fs");

function createAbiJSON(artifact, filename) {
  const data = JSON.parse(artifact.interface.format("json"));
  const object = {
    abi: data,
    address: artifact.address,
    blockNumber: artifact.deployTransaction.blockNumber,
  };
  writeFileSync(`${__dirname}/../abi/${filename}.json`, JSON.stringify(object));
}

module.exports = {
  createAbiJSON,
};
