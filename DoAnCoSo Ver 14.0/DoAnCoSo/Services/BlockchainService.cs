using DoAnCoSo.Models;
using DoAnCoSo.Models.Blockchain;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using System;

public class BlockchainService
{
    private readonly ApplicationDbContext _context;

    public BlockchainService(ApplicationDbContext context)
    {
        _context = context;
    }

    private string GenerateHash(string input)
    {
        using var sha256 = SHA256.Create();
        var bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(input));
        return BitConverter.ToString(bytes).Replace("-", "").ToLower();
    }

    private async Task<string?> GetLatestHash()
    {
        var lastBlock = await _context.BlockchainRecords
            .OrderByDescending(b => b.Id)
            .FirstOrDefaultAsync();

        return lastBlock?.Hash;
    }

    private async Task<int> GetNextBlockNumber()
    {
        int max = await _context.BlockchainRecords
            .MaxAsync(b => (int?)b.BlockNumber) ?? 0;

        return max + 1;
    }

    // ✅ Ghi blockchain cho thú cưng
    public async Task AddPetBlockAsync(int petId, string operation, string jsonData, string? performedBy = null)
    {
        var block = new BlockchainRecord
        {
            BlockNumber = await GetNextBlockNumber(),
            PreviousHash = await GetLatestHash() ?? "GENESIS",
            DataJson = jsonData,
            Operation = operation,
            RecordType = "Hồ sơ",
            ReferenceId = petId.ToString(),
            Timestamp = DateTime.Now,
            PerformedBy = performedBy ?? "Hệ thống"
        };

        block.Hash = GenerateHash($"{block.PreviousHash}{block.Timestamp}{block.DataJson}");

        _context.BlockchainRecords.Add(block);
        await _context.SaveChangesAsync();
    }

    // ✅ Ghi blockchain cho dịch vụ: Spa / Homestay / Vet
    public async Task AddAppointmentBlockAsync(int petId, int appointmentId, string recordType, string operation, string jsonData, string? performedBy = null)
    {
        var block = new BlockchainRecord
        {
            BlockNumber = await GetNextBlockNumber(),
            PreviousHash = await GetLatestHash() ?? "GENESIS",
            DataJson = jsonData,
            Operation = operation,
            RecordType = recordType, // Spa / Homestay / Vet
            ReferenceId = $"{petId}-{appointmentId}", // ✅ vừa PetId vừa AppointmentId
            Timestamp = DateTime.Now,
            PerformedBy = performedBy ?? "Hệ thống"
        };

        block.Hash = GenerateHash($"{block.PreviousHash}{block.Timestamp}{block.DataJson}");

        _context.BlockchainRecords.Add(block);
        await _context.SaveChangesAsync();
    }
}