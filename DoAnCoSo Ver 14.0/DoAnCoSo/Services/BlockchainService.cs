using DoAnCoSo.Models;
using DoAnCoSo.Models.Blockchain;
using Microsoft.EntityFrameworkCore;
using Nethereum.Web3;
using Nethereum.Web3.Accounts;
using Nethereum.Hex.HexTypes;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

public class BlockchainService
{
    private readonly ApplicationDbContext _context;
    private readonly Web3 _web3;
    private readonly string _contractAddress;

    private const string ABI = @"[
	    {""inputs"":[{""internalType"":""string"",""name"":""dataJson"",""type"":""string""}],
	     ""name"":""addRecord"",""outputs"":[],""stateMutability"":""nonpayable"",""type"":""function""}
    ]";

    public BlockchainService(ApplicationDbContext context, IConfiguration configuration)
    {
        _context = context;

        string privateKey = configuration["Blockchain:PrivateKey"]; // private key Ganache
        string rpcUrl = configuration["Blockchain:RpcUrl"];
        _contractAddress = configuration["Blockchain:ContractAddress"];

        // Tạo account từ private key và kết nối Web3
        var account = new Account(privateKey);
        _web3 = new Web3(account, rpcUrl);
    }

    private async Task<string?> GetLatestHash()
    {
        var last = await _context.BlockchainRecords
            .OrderByDescending(b => b.BlockNumber)
            .FirstOrDefaultAsync();

        return last?.Hash;
    }

    private async Task<int> GetNextBlockNumber()
    {
        int max = await _context.BlockchainRecords
            .MaxAsync(b => (int?)b.BlockNumber) ?? 0;

        return max + 1;
    }

    // Gửi JSON lên Ganache
    private async Task<string> SendToGanacheAsync(string dataJson)
    {
        var contract = _web3.Eth.GetContract(ABI, _contractAddress);
        var addFunction = contract.GetFunction("addRecord");

        // Không dùng eth_coinbase nữa, account đã được gán khi tạo Web3
        string txHash = await addFunction.SendTransactionAsync(
            _web3.TransactionManager.Account.Address,
            new HexBigInteger(300000),
            null,
            new object[] { dataJson }
        );

        return txHash;
    }

    // Lưu block vào SQL + Hash + Transaction
    private async Task SaveBlockAsync(BlockchainRecord block)
    {
        // gửi dữ liệu lên Ganache, lấy TxHash
        string txHash = await SendToGanacheAsync(block.DataJson);

        // lưu TxHash vào DB thay vì SHA256
        block.Hash = txHash;
        block.TransactionHash = txHash;

        _context.BlockchainRecords.Add(block);
        await _context.SaveChangesAsync();
    }

    // -----------------------
    //   PET BLOCK
    // -----------------------
    public async Task AddPetBlockAsync(object record, string operation, string performedBy)
    {
        var jsonData = JsonSerializer.Serialize(record);

        var block = new BlockchainRecord
        {
            BlockNumber = await GetNextBlockNumber(),
            PreviousHash = await GetLatestHash() ?? "GENESIS",
            DataJson = jsonData,
            Operation = operation,
            RecordType = "Pet",
            ReferenceId = record.GetType().GetProperty("PetId")?.GetValue(record)?.ToString()
                        ?? record.GetType().GetProperty("OriginalPetId")?.GetValue(record)?.ToString()
                        ?? "0",
            Timestamp = DateTime.Now,
            PerformedBy = performedBy
        };

        await SaveBlockAsync(block);
    }

    // PET DELETED (đã chỉnh sửa chuẩn)
    public async Task AddPetBlockAsync(DeletedPets pet, string action, string performedBy)
    {
        var recordJson = JsonSerializer.Serialize(new
        {
            pet.OriginalPetId,
            pet.Name,
            pet.Type,
            pet.Breed,
            pet.Gender,
            pet.Age,
            pet.Weight,
            pet.UserId,
            pet.ImageUrl,
            pet.DeletedAt,
            pet.DeletedBy,
            Action = action
        });

        var block = new BlockchainRecord
        {
            BlockNumber = await GetNextBlockNumber(),
            PreviousHash = await GetLatestHash() ?? "GENESIS",
            DataJson = recordJson,
            Operation = action,
            RecordType = "PetDeleted",
            ReferenceId = pet.OriginalPetId.ToString(),
            Timestamp = DateTime.Now,
            PerformedBy = performedBy
        };

        await SaveBlockAsync(block);
    }

    // -----------------------
    //   APPOINTMENT BLOCK
    // -----------------------
    public async Task AddAppointmentBlockAsync(object record, string recordType, string operation, string? performedBy = null)
    {
        if (record == null) return;

        var jsonData = JsonSerializer.Serialize(record);

        // LẤY PET ID ĐÚNG
        string referenceId = "0";
        var petIdProp = record.GetType().GetProperty("PetId");
        if (petIdProp != null)
        {
            referenceId = petIdProp.GetValue(record)?.ToString() ?? "0";
        }

        var block = new BlockchainRecord
        {
            BlockNumber = await GetNextBlockNumber(),
            PreviousHash = await GetLatestHash() ?? "GENESIS",
            DataJson = jsonData,
            Operation = operation,
            RecordType = recordType,
            ReferenceId = referenceId,   // LƯU PET ID
            Timestamp = DateTime.Now,
            PerformedBy = performedBy ?? "Hệ thống"
        };

        await SaveBlockAsync(block);
    }
}