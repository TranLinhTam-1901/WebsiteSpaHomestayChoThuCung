using System.Security.Cryptography;
using System.Text;

namespace DoAnCoSo.Models.Blockchain
{
    public class Block
    {
        public int Index { get; set; }
        public DateTime Timestamp { get; set; }
        public string Data { get; set; } // có thể serialize JSON từ Appointment, PetServiceRecord
        public string PreviousHash { get; set; }
        public string Hash { get; set; }

        public Block(int index, DateTime timestamp, string data, string previousHash)
        {
            Index = index;
            Timestamp = timestamp;
            Data = data;
            PreviousHash = previousHash;
            Hash = CalculateHash();
        }

        public string CalculateHash()
        {
            using (var sha256 = SHA256.Create())
            {
                var rawData = $"{Index}-{Timestamp}-{Data}-{PreviousHash}";
                var bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(rawData));
                return Convert.ToBase64String(bytes);
            }
        }
    }

    public class Blockchain
    {
        public List<Block> Chain { get; set; }

        public Blockchain()
        {
            Chain = new List<Block> { CreateGenesisBlock() };
        }

        private Block CreateGenesisBlock()
        {
            return new Block(0, DateTime.Now, "Genesis Block", "0");
        }

        public Block GetLatestBlock()
        {
            return Chain.Last();
        }

        public void AddBlock(string data)
        {
            var latestBlock = GetLatestBlock();
            var newBlock = new Block(latestBlock.Index + 1, DateTime.Now, data, latestBlock.Hash);
            Chain.Add(newBlock);
        }

        public bool IsValid()
        {
            for (int i = 1; i < Chain.Count; i++)
            {
                var current = Chain[i];
                var previous = Chain[i - 1];

                if (current.Hash != current.CalculateHash()) return false;
                if (current.PreviousHash != previous.Hash) return false;
            }
            return true;
        }
    }
}
