using DoAnCoSo.Models.Blockchain;
using System.Collections.Generic;

namespace DoAnCoSo.ViewModels
{
    public class BlockchainViewModel
    {
        public List<BlockchainRecord> Records { get; set; } = new List<BlockchainRecord>();
        public Dictionary<string, string> PetsDict { get; set; } = new Dictionary<string, string>();
        public string CurrentPetName { get; set; } = null; // để ViewByPet hiển thị tên thú cưng
    }
}
