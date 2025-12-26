namespace DoAnCoSo.ViewModels.VariantPreview
{
    // Request gửi từ View (JSON)
    public class PreviewOptionRequest
    {
        public int ProductId { get; set; }
        public List<PreviewGroupDto> Groups { get; set; } = new();
    }

    public class PreviewGroupDto
    {
        public int GroupId { get; set; }      // Nhóm cũ > 0, nhóm mới = 0
        public string Name { get; set; } = "";
        public List<PreviewValueDto> Values { get; set; } = new();
    }

    public class PreviewValueDto
    {
        public int Id { get; set; }           // Value cũ > 0, value mới = 0
        public string Text { get; set; } = "";
    }

    // -------------------------
    // RESPONSE kết quả trả về
    // -------------------------
    public class PreviewOptionGroupResult
    {
        public int GroupId { get; set; }
        public string Name { get; set; } = "";
        public List<PreviewOptionValueResult> Values { get; set; } = new();
    }

    public class PreviewOptionValueResult
    {
        public int Id { get; set; }
        public string Text { get; set; } = "";
    }
}
