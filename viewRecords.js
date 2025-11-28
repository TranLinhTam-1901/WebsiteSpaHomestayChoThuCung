const Web3 = require("web3");
const readline = require("readline");

// Kết nối Ganache
const web3 = new Web3.Web3("http://127.0.0.1:7545");

// ABI PawHouse
const abi = [
    {
        "inputs":[{"internalType":"string","name":"dataJson","type":"string"}],
        "name":"addRecord",
        "outputs":[],
        "stateMutability":"nonpayable",
        "type":"function"
    }
];

// Contract address từ Ganache
const contractAddress = web3.utils.toChecksumAddress("0x228acb89776001231B2F313B88ceE57aC7546928");

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

async function showBlock(blockNumber) {
    try {
        const latestBlock = await web3.eth.getBlockNumber();

        if (blockNumber > latestBlock || blockNumber < 0) {
            console.log(`Block không hợp lệ! Chỉ có từ 0 đến ${latestBlock}`);
            return;
        }

        const block = await web3.eth.getBlock(blockNumber, true);
        if (!block.transactions || block.transactions.length === 0) {
            console.log(`Block ${blockNumber} không có transaction nào.`);
            return;
        }

        console.log(`\n#Block ${blockNumber} \n - Hash: ${block.hash} \n - Prehash: ${block.parentHash}`);
        for (const tx of block.transactions) {
            if (tx.to && tx.to.toLowerCase() === contractAddress.toLowerCase()) {
                const addRecordSelector = "0x" + web3.eth.abi.encodeFunctionSignature("addRecord(string)").slice(2);
                if (tx.input.startsWith(addRecordSelector)) {
                    const decoded = web3.eth.abi.decodeParameters(
                        ["string"],
                        "0x" + tx.input.slice(10)
                    );
                    let dataJson;
                    try {
                        dataJson = JSON.parse(decoded[0]);
                    } catch {
                        dataJson = decoded[0];
                    }
                    console.log("Decoded dataJson:");
                    console.log(typeof dataJson === "object" 
                        ? JSON.stringify(dataJson, null, 2) 
                        : dataJson
                    );
                }
            }
        }
    } catch (err) {
        console.error("Lỗi:", err.message);
    }
}

async function mainMenu() {
    const latestBlock = await web3.eth.getBlockNumber();
    console.log(`\n=== Ganache hiện có tổng số block: ${latestBlock} ===\n`);

    const menu = () => {
        console.log("\nChọn option:");
        console.log("1. Xem dữ liệu block");
        console.log("2. Thoát");

        rl.question("Nhập số option: ", async (choice) => {
            if (choice === "1") {
                rl.question("Nhập số block muốn xem: ", async (blockInput) => {
                    const blockNumber = parseInt(blockInput);
                    await showBlock(blockNumber);
                    menu(); // quay lại menu sau khi xem xong
                });
            } else if (choice === "2") {
                console.log("Thoát chương trình.");
                rl.close();
            } else {
                console.log("Option không hợp lệ!");
                menu(); // quay lại menu
            }
        });
    };

    menu();
}

mainMenu();
